package io.github.wesleyosantos91.catalog.feature.product.domain.exception;

/**
 * Violação de uma regra de negócio em um campo do produto.
 *
 * @param field nome do campo no contrato (por exemplo {@code sku})
 * @param message descrição da regra violada
 */
public record Violation(String field, String message) {
}
