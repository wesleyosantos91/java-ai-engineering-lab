package io.github.wesleyosantos91.catalog.feature.product.service;

/** Já existe um produto com o SKU normalizado informado. */
public final class ProductSkuConflictException extends RuntimeException {

	private final String sku;

	public ProductSkuConflictException(String sku, Throwable cause) {
		super("Product SKU already exists: " + sku, cause);
		this.sku = sku;
	}

	public String sku() {
		return sku;
	}

}
