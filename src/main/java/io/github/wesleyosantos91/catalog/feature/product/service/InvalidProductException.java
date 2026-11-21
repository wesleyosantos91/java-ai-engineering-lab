package io.github.wesleyosantos91.catalog.feature.product.service;

import java.util.List;

/** Os dados informados violam as regras do produto; nada foi persistido. */
public final class InvalidProductException extends RuntimeException {

	private final List<ProductFieldError> errors;

	public InvalidProductException(List<ProductFieldError> errors) {
		super("Invalid product: " + errors.size() + " field error(s)");
		this.errors = List.copyOf(errors);
	}

	public List<ProductFieldError> errors() {
		return errors;
	}

}
