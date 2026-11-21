package io.github.wesleyosantos91.catalog.feature.product.api.rest.v1.request;

import io.github.wesleyosantos91.catalog.feature.product.service.CreateProductCommand;
import java.math.BigDecimal;
import tools.jackson.databind.annotation.JsonDeserialize;

/**
 * Corpo de {@code POST /api/v1/products} (PRD-001, seção 6.1). Propriedades desconhecidas são
 * rejeitadas pela configuração global {@code fail-on-unknown-properties}. Os campos de texto só
 * aceitam strings JSON e o preço só aceita número JSON (decisão D-01 da FEAT-0001), sem coerção.
 */
public record CreateProductRequest(@JsonDeserialize(using = JsonStringOnlyDeserializer.class) String sku,
		@JsonDeserialize(using = JsonStringOnlyDeserializer.class) String name,
		@JsonDeserialize(using = JsonStringOnlyDeserializer.class) String description,
		@JsonDeserialize(using = JsonNumberOnlyDeserializer.class) BigDecimal price) {

	public CreateProductCommand toCommand() {
		return new CreateProductCommand(sku, name, description, price);
	}

}
