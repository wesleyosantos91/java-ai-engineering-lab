package io.github.wesleyosantos91.catalog.feature.product.domain.valueobject;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.wesleyosantos91.catalog.feature.product.domain.exception.ProductValidationException;
import java.math.BigDecimal;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;

class PriceTest {

	@ParameterizedTest
	@ValueSource(strings = { "0.01", "12.9", "12.90", "99999999.99", "10.500", "7" })
	void acceptsPositiveValuesUpToTwoDecimalPlacesAndTheUpperLimit(String raw) {
		Price price = Price.of(new BigDecimal(raw));
		assertThat(price.value()).isEqualByComparingTo(raw);
		assertThat(price.value().scale()).isEqualTo(2);
	}

	@Test
	void keepsExactValueWithoutRounding() {
		assertThat(Price.of(new BigDecimal("10.500")).value()).isEqualTo(new BigDecimal("10.50"));
	}

	@ParameterizedTest
	@ValueSource(strings = { "0", "0.00", "-0.01", "-1", "10.505", "0.001", "100000000.00", "99999999.991" })
	void rejectsNonPositiveTooPreciseOrAboveLimitValues(String raw) {
		assertRejected(new BigDecimal(raw));
	}

	@Test
	void rejectsMissingPrice() {
		assertRejected(null);
	}

	private static void assertRejected(BigDecimal raw) {
		assertThatThrownBy(() -> Price.of(raw))
			.isInstanceOfSatisfying(ProductValidationException.class,
					e -> assertThat(e.violations()).singleElement().satisfies(v -> assertThat(v.field()).isEqualTo("price")));
	}

}
