package io.github.wesleyosantos91.catalog.feature.product.domain.entity;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.wesleyosantos91.catalog.feature.product.domain.exception.ProductValidationException;
import io.github.wesleyosantos91.catalog.feature.product.domain.exception.Violation;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import org.junit.jupiter.api.Test;

class ProductTest {

	private static final UUID ID = UUID.fromString("0f8fad5b-d9cb-469f-a165-70867728950e");
	private static final Instant NOW = Instant.parse("2026-11-20T12:00:00.123456Z");

	@Test
	void createsNormalizedProductWithServerManagedFields() {
		Product product = Product.create(ID, NOW, " abc-001 ", " Caneta azul ", "  ", new BigDecimal("12.9"));

		assertThat(product.id()).isEqualTo(ID);
		assertThat(product.sku().value()).isEqualTo("ABC-001");
		assertThat(product.name().value()).isEqualTo("Caneta azul");
		assertThat(product.description().value()).isNull();
		assertThat(product.price().value()).isEqualTo(new BigDecimal("12.90"));
		assertThat(product.createdAt()).isEqualTo(NOW);
		assertThat(product.updatedAt()).isEqualTo(product.createdAt());
	}

	@Test
	void reportsEveryInvalidFieldAtOnce() {
		assertThatThrownBy(() -> Product.create(ID, NOW, "x", "", "d".repeat(501), BigDecimal.ZERO))
			.isInstanceOfSatisfying(ProductValidationException.class, e -> assertThat(e.violations())
				.extracting(Violation::field)
				.containsExactly("sku", "name", "description", "price"));
	}

	@Test
	void reportsOnlyTheInvalidField() {
		assertThatThrownBy(() -> Product.create(ID, NOW, "ABC-001", "Caneta", null, null))
			.isInstanceOfSatisfying(ProductValidationException.class,
					e -> assertThat(e.violations()).extracting(Violation::field).containsExactly("price"));
	}

	@Test
	void requiresServerManagedFields() {
		assertThatThrownBy(() -> Product.create(null, NOW, "ABC-001", "Caneta", null, BigDecimal.ONE))
			.isInstanceOf(NullPointerException.class);
		assertThatThrownBy(() -> Product.create(ID, null, "ABC-001", "Caneta", null, BigDecimal.ONE))
			.isInstanceOf(NullPointerException.class);
	}

}
