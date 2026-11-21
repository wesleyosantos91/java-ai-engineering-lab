package io.github.wesleyosantos91.catalog.feature.product.api.rest.v1.response;

import io.github.wesleyosantos91.catalog.feature.product.service.ProductDetails;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/** Representação completa de um produto (PRD-001, seção 6.2). */
public record ProductResponse(UUID id, String sku, String name, String description, BigDecimal price,
		Instant createdAt, Instant updatedAt) {

	public static ProductResponse from(ProductDetails product) {
		return new ProductResponse(product.id(), product.sku(), product.name(), product.description(),
				product.price(), product.createdAt(), product.updatedAt());
	}

}
