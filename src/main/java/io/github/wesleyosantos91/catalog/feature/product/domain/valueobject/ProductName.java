package io.github.wesleyosantos91.catalog.feature.product.domain.valueobject;

import io.github.wesleyosantos91.catalog.feature.product.domain.exception.ProductValidationException;

/** Nome do produto (PRD-001, seção 4.2): sem espaços externos, de 3 a 120 caracteres. */
public record ProductName(String value) {

	static final int MIN_LENGTH = 3;
	static final int MAX_LENGTH = 120;

	public ProductName {
		if (value == null || value.length() < MIN_LENGTH || value.length() > MAX_LENGTH) {
			throw ProductValidationException.of("name", "must have 3 to 120 characters after trimming");
		}
	}

	public static ProductName of(String raw) {
		return new ProductName(raw == null ? null : raw.strip());
	}

}
