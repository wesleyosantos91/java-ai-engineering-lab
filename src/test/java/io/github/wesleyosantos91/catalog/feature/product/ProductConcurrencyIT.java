package io.github.wesleyosantos91.catalog.feature.product;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.wesleyosantos91.catalog.TestcontainersConfiguration;
import java.util.List;
import java.util.concurrent.CyclicBarrier;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.RepeatedTest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.simple.JdbcClient;

/**
 * FEAT-0001, CA-08: duas criações simultâneas com o mesmo SKU normalizado resultam em exatamente um
 * produto. Uma barreira libera as requisições juntas; a repetição reduz falsos positivos.
 */
@Import(TestcontainersConfiguration.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class ProductConcurrencyIT {

	@Value("${local.server.port}")
	int port;

	@Autowired
	JdbcClient jdbc;

	@BeforeEach
	void cleanDatabase() {
		jdbc.sql("DELETE FROM product").update();
	}

	@RepeatedTest(10)
	void onlyOneOfTwoConcurrentCreationsWithTheSameSkuSucceeds() throws Exception {
		ProductApiClient api = new ProductApiClient(port);
		CyclicBarrier start = new CyclicBarrier(2);
		try (ExecutorService executor = Executors.newFixedThreadPool(2)) {
			List<Future<Integer>> results = List.of("dup-001", "DUP-001").stream()
				.map(sku -> executor.submit(() -> {
					start.await();
					return api.create("{\"sku\": \"" + sku + "\", \"name\": \"Caneta\", \"price\": 1.00}").statusCode();
				}))
				.toList();

			List<Integer> statuses = results.stream().map(ProductConcurrencyIT::join).sorted().toList();
			assertThat(statuses).containsExactly(201, 409);
		}
		assertThat(jdbc.sql("SELECT count(*) FROM product WHERE sku = 'DUP-001'").query(Long.class).single())
			.isEqualTo(1);
	}

	private static Integer join(Future<Integer> future) {
		try {
			return future.get();
		}
		catch (Exception e) {
			throw new IllegalStateException(e);
		}
	}

}
