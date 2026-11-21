package io.github.wesleyosantos91.catalog.feature.product.domain.valueobject;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.wesleyosantos91.catalog.feature.product.domain.exception.ProductValidationException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

class ProductDescriptionTest {

	@ParameterizedTest
	@NullAndEmptySource
	@ValueSource(strings = { " ", "   ", "\t \n" })
	void normalizesMissingOrBlankDescriptionToNull(String raw) {
		assertThat(ProductDescription.of(raw).value()).isNull();
	}

	@Test
	void trimsExternalSpaces() {
		assertThat(ProductDescription.of("  Tinta gel  ").value()).isEqualTo("Tinta gel");
	}

	@Test
	void acceptsExactly500CharactersAfterNormalization() {
		assertThat(ProductDescription.of("  " + "d".repeat(500) + "  ").value()).hasSize(500);
	}

	@Test
	void rejectsMoreThan500CharactersAfterNormalization() {
		assertThatThrownBy(() -> ProductDescription.of("d".repeat(501)))
			.isInstanceOfSatisfying(ProductValidationException.class,
					e -> assertThat(e.violations()).singleElement()
						.satisfies(v -> assertThat(v.field()).isEqualTo("description")));
	}

}
