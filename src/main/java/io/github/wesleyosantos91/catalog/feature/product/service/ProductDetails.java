package io.github.wesleyosantos91.catalog.feature.product.service;

import io.github.wesleyosantos91.catalog.feature.product.domain.entity.Product;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

/** Representação de um produto exposta pelo service, sem tipos do domínio. */
public record ProductDetails(UUID id, String sku, String name, String description, BigDecimal price,
		Instant createdAt, Instant updatedAt) {

	static ProductDetails from(Product product) {
		return new ProductDetails(product.id(), product.sku().value(), product.name().value(),
				product.description().value(), product.price().value(), product.createdAt(), product.updatedAt());
	}

}
