package io.github.wesleyosantos91.catalog.feature.product.api.rest.v1.request;

import io.github.wesleyosantos91.catalog.feature.product.service.CreateProductCommand;
import java.math.BigDecimal;
import tools.jackson.databind.annotation.JsonDeserialize;

/**
 * Corpo de {@code POST /api/v1/products} (PRD-001, seção 6.1). Propriedades desconhecidas são
 * rejeitadas pela configuração global {@code fail-on-unknown-properties}; o preço só é aceito
 * como número JSON (decisão D-01 da FEAT-0001).
 */
public record CreateProductRequest(String sku, String name, String description,
		@JsonDeserialize(using = JsonNumberOnlyDeserializer.class) BigDecimal price) {

	public CreateProductCommand toCommand() {
		return new CreateProductCommand(sku, name, description, price);
	}

}
