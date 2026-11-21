package io.github.wesleyosantos91.catalog.feature.product.service;

import java.math.BigDecimal;

/** Dados de entrada para criar um produto, ainda não normalizados. */
public record CreateProductCommand(String sku, String name, String description, BigDecimal price) {
}
