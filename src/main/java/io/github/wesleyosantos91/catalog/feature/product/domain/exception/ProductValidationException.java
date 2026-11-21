package io.github.wesleyosantos91.catalog.feature.product.domain.exception;

import java.util.List;

/** Um ou mais campos do produto violam as regras do PRD-001, seção 4. */
public final class ProductValidationException extends RuntimeException {

	private final List<Violation> violations;

	public ProductValidationException(List<Violation> violations) {
		super("Product validation failed: " + violations.size() + " violation(s)");
		this.violations = List.copyOf(violations);
	}

	public static ProductValidationException of(String field, String message) {
		return new ProductValidationException(List.of(new Violation(field, message)));
	}

	public List<Violation> violations() {
		return violations;
	}

}
