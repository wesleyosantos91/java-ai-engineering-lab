package io.github.wesleyosantos91.catalog.feature.product.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import io.github.wesleyosantos91.catalog.feature.product.domain.entity.Product;
import io.github.wesleyosantos91.catalog.feature.product.persistence.repository.ProductRepository;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.dao.DuplicateKeyException;

class ProductServiceTest {

	private static final Instant NOW = Instant.parse("2026-11-20T12:00:00.123456789Z");

	private ProductRepository repository;
	private ProductService service;

	@BeforeEach
	void setUp() {
		repository = mock(ProductRepository.class);
		service = new ProductService(repository, Clock.fixed(NOW, ZoneOffset.UTC));
	}

	@Test
	void persistsAndReturnsNormalizedProduct() {
		ProductDetails created = service.create(new CreateProductCommand(" abc-001 ", " Caneta ", " ", new BigDecimal("12.9")));

		ArgumentCaptor<Product> inserted = ArgumentCaptor.forClass(Product.class);
		verify(repository).insert(inserted.capture());
		assertThat(created.id()).isNotNull().isEqualTo(inserted.getValue().id());
		assertThat(created.sku()).isEqualTo("ABC-001");
		assertThat(created.name()).isEqualTo("Caneta");
		assertThat(created.description()).isNull();
		assertThat(created.price()).isEqualTo(new BigDecimal("12.90"));
		// timestamptz guarda microssegundos (D-06): a resposta deve ser igual ao valor persistido.
		assertThat(created.createdAt()).isEqualTo(Instant.parse("2026-11-20T12:00:00.123456Z"));
		assertThat(created.updatedAt()).isEqualTo(created.createdAt());
	}

	@Test
	void generatesDistinctIds() {
		CreateProductCommand command = new CreateProductCommand("ABC-001", "Caneta", null, BigDecimal.TEN);
		assertThat(service.create(command).id()).isNotEqualTo(service.create(command).id());
	}

	@Test
	void translatesValidationViolationsWithoutPersisting() {
		assertThatThrownBy(() -> service.create(new CreateProductCommand("x", "Caneta", null, BigDecimal.ZERO)))
			.isInstanceOfSatisfying(InvalidProductException.class, e -> assertThat(e.errors())
				.containsExactly(new ProductFieldError("sku", e.errors().get(0).message()),
						new ProductFieldError("price", e.errors().get(1).message())));
		verify(repository, never()).insert(any());
	}

	@Test
	void translatesDatabaseUniquenessViolationToSkuConflict() {
		doThrow(new DuplicateKeyException("duplicate key")).when(repository).insert(any());

		assertThatThrownBy(() -> service.create(new CreateProductCommand("abc-001", "Caneta", null, BigDecimal.ONE)))
			.isInstanceOfSatisfying(ProductSkuConflictException.class, e -> assertThat(e.sku()).isEqualTo("ABC-001"));
	}

}
