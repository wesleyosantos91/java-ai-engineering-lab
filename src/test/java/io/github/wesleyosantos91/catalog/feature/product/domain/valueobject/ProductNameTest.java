package io.github.wesleyosantos91.catalog.feature.product.domain.valueobject;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.wesleyosantos91.catalog.feature.product.domain.exception.ProductValidationException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

class ProductNameTest {

	@Test
	void trimsExternalSpaces() {
		assertThat(ProductName.of("  Caneta azul  ").value()).isEqualTo("Caneta azul");
	}

	@Test
	void acceptsLengthBoundaries() {
		assertThat(ProductName.of("abc").value()).hasSize(3);
		assertThat(ProductName.of("a".repeat(120)).value()).hasSize(120);
		assertThat(ProductName.of("  " + "a".repeat(120) + "  ").value()).hasSize(120);
	}

	@ParameterizedTest
	@NullAndEmptySource
	@ValueSource(strings = { "   ", "ab", "  ab  " })
	void rejectsBlankOrShortNames(String raw) {
		assertRejected(raw);
	}

	@Test
	void rejectsNamesLongerThan120Characters() {
		assertRejected("a".repeat(121));
	}

	private static void assertRejected(String raw) {
		assertThatThrownBy(() -> ProductName.of(raw))
			.isInstanceOfSatisfying(ProductValidationException.class,
					e -> assertThat(e.violations()).singleElement().satisfies(v -> assertThat(v.field()).isEqualTo("name")));
	}

}
