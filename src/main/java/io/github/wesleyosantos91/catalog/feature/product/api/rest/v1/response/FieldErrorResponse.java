package io.github.wesleyosantos91.catalog.feature.product.api.rest.v1.response;

/** Item da extensão {@code errors} de um {@code ProblemDetail} de validação (decisão D-03). */
public record FieldErrorResponse(String field, String message) {
}
