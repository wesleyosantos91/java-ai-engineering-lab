package io.github.wesleyosantos91.catalog.feature.product.domain.valueobject;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import io.github.wesleyosantos91.catalog.feature.product.domain.exception.ProductValidationException;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.NullAndEmptySource;
import org.junit.jupiter.params.provider.ValueSource;

class SkuTest {

	@Test
	void normalizesByTrimmingAndUppercasing() {
		assertThat(Sku.of("  abc-001  ").value()).isEqualTo("ABC-001");
	}

	@Test
	void treatsCaseVariantsAsTheSameSku() {
		assertThat(Sku.of("abc-001")).isEqualTo(Sku.of("ABC-001"));
	}

	@ParameterizedTest
	@ValueSource(strings = { "AB1", "A_B", "1-2", "ABCDEFGHIJKLMNOPQRSTUVWXYZ012345", "a1_b-c" })
	void acceptsValidSkus(String raw) {
		assertThat(Sku.of(raw).value()).isEqualTo(raw.trim().toUpperCase(java.util.Locale.ROOT));
	}

	@ParameterizedTest
	@NullAndEmptySource
	@ValueSource(strings = { "   ", "AB", "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456", "-ABC", "_ABC", "AB C", "ABC.1", "ÁBC" })
	void rejectsInvalidSkus(String raw) {
		assertThatThrownBy(() -> Sku.of(raw))
			.isInstanceOfSatisfying(ProductValidationException.class,
					e -> assertThat(e.violations()).singleElement().satisfies(v -> assertThat(v.field()).isEqualTo("sku")));
	}

}
