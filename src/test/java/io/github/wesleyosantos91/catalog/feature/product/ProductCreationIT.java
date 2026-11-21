package io.github.wesleyosantos91.catalog.feature.product;

import static org.assertj.core.api.Assertions.assertThat;

import io.github.wesleyosantos91.catalog.TestcontainersConfiguration;
import java.math.BigDecimal;
import java.net.http.HttpResponse;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.simple.JdbcClient;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;

/** FEAT-0001: criação de produto via HTTP real e PostgreSQL (Testcontainers). */
@Import(TestcontainersConfiguration.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class ProductCreationIT {

	private static final String PROBLEM_JSON = "application/problem+json";

	@Value("${local.server.port}")
	int port;

	@Autowired
	JdbcClient jdbc;

	@Autowired
	ObjectMapper json;

	ProductApiClient api;

	@BeforeEach
	void setUp() {
		api = new ProductApiClient(port);
		jdbc.sql("DELETE FROM product").update();
	}

	// CA-01 — criação válida.
	@Test
	void createsNormalizedProductAndReturnsLocation() {
		HttpResponse<String> response = api.create("""
				{"sku": " abc-001 ", "name": " Caneta azul ", "description": "Tinta gel", "price": 12.90}
				""");

		assertThat(response.statusCode()).isEqualTo(201);
		JsonNode body = json.readTree(response.body());
		UUID id = UUID.fromString(body.get("id").asString());
		assertThat(body.get("sku").asString()).isEqualTo("ABC-001");
		assertThat(body.get("name").asString()).isEqualTo("Caneta azul");
		assertThat(body.get("description").asString()).isEqualTo("Tinta gel");
		assertThat(response.body()).contains("\"price\":12.90");
		assertThat(body.get("createdAt").asString()).endsWith("Z");
		assertThat(body.get("updatedAt").asString()).isEqualTo(body.get("createdAt").asString());
		assertThat(response.headers().firstValue("Location"))
			.hasValue(api.productsUri() + "/" + id);

		Map<String, Object> row = jdbc.sql("SELECT * FROM product WHERE id = ?").param(id).query().singleRow();
		assertThat(row).containsEntry("sku", "ABC-001")
			.containsEntry("name", "Caneta azul")
			.containsEntry("description", "Tinta gel")
			.containsEntry("price", new BigDecimal("12.90"));
		Instant createdAt = jdbc.sql("SELECT created_at FROM product WHERE id = ?").param(id).query(Instant.class).single();
		assertThat(createdAt).isEqualTo(Instant.parse(body.get("createdAt").asString()));
	}

	// CA-02 — SKU duplicado após normalização.
	@Test
	void rejectsSkuThatAlreadyExistsAfterNormalization() {
		assertThat(api.create(valid("ABC-001")).statusCode()).isEqualTo(201);

		HttpResponse<String> response = api.create(valid("abc-001"));

		assertProblem(response, 409, "PRODUCT_SKU_CONFLICT");
		assertThat(response.body()).doesNotContain("product_sku_uk", "duplicate key", "SQL", "Exception");
		assertThat(count()).isEqualTo(1);
	}

	// CA-03 — preço inválido, incluindo limites (PRD 4.3).
	@ParameterizedTest
	@ValueSource(strings = { "0", "0.00", "-1", "10.505", "100000000.00" })
	void rejectsInvalidPrice(String price) {
		HttpResponse<String> response = api.create(
				"{\"sku\": \"ABC-001\", \"name\": \"Caneta\", \"price\": " + price + "}");

		assertProblem(response, 400, "VALIDATION_FAILED");
		assertThat(errorFields(response)).containsExactly("price");
		assertThat(count()).isZero();
	}

	// D-01 — preço como string JSON é rejeitado.
	@Test
	void rejectsPriceSentAsJsonString() {
		HttpResponse<String> response = api.create("{\"sku\": \"ABC-001\", \"name\": \"Caneta\", \"price\": \"12.90\"}");

		assertProblem(response, 400, "VALIDATION_FAILED");
		assertThat(errorFields(response)).containsExactly("price");
		assertThat(count()).isZero();
	}

	// D-02 e D-05 — zeros à direita são aceitos; a resposta usa 2 casas.
	@Test
	void acceptsTrailingZerosBeyondTwoDecimalPlaces() {
		HttpResponse<String> response = api.create("{\"sku\": \"ABC-001\", \"name\": \"Caneta\", \"price\": 10.500}");

		assertThat(response.statusCode()).isEqualTo(201);
		assertThat(response.body()).contains("\"price\":10.50");
	}

	// CA-10 — campos desconhecidos ou gerenciados pelo servidor.
	@ParameterizedTest
	@ValueSource(strings = { "id", "createdAt", "updatedAt", "stock" })
	void rejectsUnknownOrServerManagedFields(String field) {
		HttpResponse<String> response = api.create(
				"{\"sku\": \"ABC-001\", \"name\": \"Caneta\", \"price\": 1.00, \"" + field + "\": \"x\"}");

		assertProblem(response, 400, "VALIDATION_FAILED");
		assertThat(errorFields(response)).containsExactly(field);
		assertThat(count()).isZero();
	}

	// PRD 6.1 — sku, name e description são strings JSON; outros tipos não são convertidos.
	@ParameterizedTest
	@ValueSource(strings = { "\"sku\": 123, \"name\": \"Caneta\"", "\"sku\": \"ABC-001\", \"name\": true",
			"\"sku\": \"ABC-001\", \"name\": \"Caneta\", \"description\": 42",
			"\"sku\": [\"ABC-001\"], \"name\": \"Caneta\"" })
	void rejectsNonStringTextFields(String members) {
		HttpResponse<String> response = api.create("{" + members + ", \"price\": 1.00}");

		assertProblem(response, 400, "VALIDATION_FAILED");
		assertThat(errorFields(response)).hasSize(1).isSubsetOf("sku", "name", "description");
		assertThat(count()).isZero();
	}

	// Negociação de conteúdo: um formato de resposta não suportado é rejeitado antes de gravar.
	@Test
	void rejectsUnsupportedResponseMediaTypeWithoutPersisting() {
		HttpResponse<String> response = api.create(valid("ABC-001"), "text/html");

		assertThat(response.statusCode()).isEqualTo(406);
		assertThat(count()).isZero();
	}

	// CA-11 — descrição omitida, nula, vazia ou só com espaços vira null.
	@ParameterizedTest
	@ValueSource(strings = { "", ", \"description\": null", ", \"description\": \"\"", ", \"description\": \"   \"" })
	void normalizesMissingOrBlankDescriptionToNull(String descriptionMember) {
		HttpResponse<String> response = api.create(
				"{\"sku\": \"ABC-001\", \"name\": \"Caneta\", \"price\": 1.00" + descriptionMember + "}");

		assertThat(response.statusCode()).isEqualTo(201);
		assertThat(json.readTree(response.body()).get("description").isNull()).isTrue();
		assertThat(jdbc.sql("SELECT description FROM product").query(String.class).optional()).isEmpty();
	}

	// VAL-01 — todas as violações de uma vez, incluindo obrigatórios ausentes ou nulos.
	@Test
	void reportsEveryInvalidField() {
		HttpResponse<String> response = api.create("{\"sku\": \"AB\", \"price\": null}");

		assertProblem(response, 400, "VALIDATION_FAILED");
		assertThat(errorFields(response)).containsExactly("sku", "name", "price");
		assertThat(count()).isZero();
	}

	// ERR-01 — corpo ausente ou JSON malformado, sem detalhes internos.
	@ParameterizedTest
	@ValueSource(strings = { "", "{", "[]", "{\"sku\": }" })
	void rejectsMalformedBodyWithoutLeakingInternals(String body) {
		HttpResponse<String> response = api.create(body);

		assertProblem(response, 400, "VALIDATION_FAILED");
		assertThat(response.body()).doesNotContain("Exception", "jackson", "at io.", "at org.", "line:", "column:");
		assertThat(count()).isZero();
	}

	private static String valid(String sku) {
		return "{\"sku\": \"" + sku + "\", \"name\": \"Caneta\", \"price\": 1.00}";
	}

	private void assertProblem(HttpResponse<String> response, int status, String code) {
		assertThat(response.statusCode()).isEqualTo(status);
		assertThat(response.headers().firstValue("Content-Type")).hasValueSatisfying(
				type -> assertThat(type).startsWith(PROBLEM_JSON));
		JsonNode body = json.readTree(response.body());
		assertThat(body.get("status").asInt()).isEqualTo(status);
		assertThat(body.get("code").asString()).isEqualTo(code);
		assertThat(body.hasNonNull("title")).isTrue();
		assertThat(body.get("instance").asString()).isEqualTo("/api/v1/products");
	}

	private List<String> errorFields(HttpResponse<String> response) {
		JsonNode errors = json.readTree(response.body()).get("errors");
		assertThat(errors).isNotNull();
		return errors.valueStream().map(error -> error.get("field").asString()).toList();
	}

	private long count() {
		return jdbc.sql("SELECT count(*) FROM product").query(Long.class).single();
	}

}
