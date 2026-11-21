package io.github.wesleyosantos91.catalog.feature.product.domain.valueobject;

import io.github.wesleyosantos91.catalog.feature.product.domain.exception.ProductValidationException;

/**
 * Descrição opcional (PRD-001, seção 4.2): ausente, vazia ou só com espaços é normalizada para
 * {@code null}; caso contrário, sem espaços externos e com no máximo 500 caracteres.
 */
public record ProductDescription(String value) {

	static final int MAX_LENGTH = 500;

	public ProductDescription {
		if (value != null && (value.isBlank() || value.length() > MAX_LENGTH)) {
			throw ProductValidationException.of("description", "must have at most 500 characters after trimming");
		}
	}

	public static ProductDescription of(String raw) {
		String normalized = raw == null ? null : raw.strip();
		return new ProductDescription(normalized == null || normalized.isEmpty() ? null : normalized);
	}

}
