package io.github.wesleyosantos91.catalog.feature.product.domain.valueobject;

import io.github.wesleyosantos91.catalog.feature.product.domain.exception.ProductValidationException;
import java.math.BigDecimal;

/**
 * Preço em BRL (PRD-001, seção 4.3): maior que zero, até R$ 99.999.999,99 e com no máximo
 * duas casas decimais significativas, sem arredondamento. Representado sempre com escala 2.
 */
public record Price(BigDecimal value) {

	static final BigDecimal MAX = new BigDecimal("99999999.99");
	private static final int SCALE = 2;

	public Price {
		if (value == null || value.signum() <= 0 || value.compareTo(MAX) > 0
				|| value.stripTrailingZeros().scale() > SCALE) {
			throw ProductValidationException.of("price",
					"must be greater than 0, at most 99999999.99 and have at most 2 decimal places");
		}
		value = value.setScale(SCALE);
	}

	public static Price of(BigDecimal raw) {
		return new Price(raw);
	}

}
