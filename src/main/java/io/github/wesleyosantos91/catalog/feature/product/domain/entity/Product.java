package io.github.wesleyosantos91.catalog.feature.product.domain.entity;

import io.github.wesleyosantos91.catalog.feature.product.domain.exception.ProductValidationException;
import io.github.wesleyosantos91.catalog.feature.product.domain.exception.Violation;
import io.github.wesleyosantos91.catalog.feature.product.domain.valueobject.Price;
import io.github.wesleyosantos91.catalog.feature.product.domain.valueobject.ProductDescription;
import io.github.wesleyosantos91.catalog.feature.product.domain.valueobject.ProductName;
import io.github.wesleyosantos91.catalog.feature.product.domain.valueobject.Sku;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;
import java.util.UUID;
import java.util.function.Supplier;

/** Produto do catálogo (PRD-001, seção 4). Instâncias válidas são criadas por {@link #create}. */
public record Product(UUID id, Sku sku, ProductName name, ProductDescription description, Price price,
		Instant createdAt, Instant updatedAt) {

	public Product {
		Objects.requireNonNull(id, "id");
		Objects.requireNonNull(sku, "sku");
		Objects.requireNonNull(name, "name");
		Objects.requireNonNull(description, "description");
		Objects.requireNonNull(price, "price");
		Objects.requireNonNull(createdAt, "createdAt");
		Objects.requireNonNull(updatedAt, "updatedAt");
	}

	/**
	 * Normaliza e valida os campos editáveis, reportando todas as violações de uma vez. Na criação,
	 * {@code updatedAt} é igual a {@code createdAt}.
	 */
	public static Product create(UUID id, Instant now, String sku, String name, String description,
			BigDecimal price) {
		Objects.requireNonNull(id, "id");
		Objects.requireNonNull(now, "now");
		List<Violation> violations = new ArrayList<>();
		Sku validSku = collect(() -> Sku.of(sku), violations);
		ProductName validName = collect(() -> ProductName.of(name), violations);
		ProductDescription validDescription = collect(() -> ProductDescription.of(description), violations);
		Price validPrice = collect(() -> Price.of(price), violations);
		if (!violations.isEmpty()) {
			throw new ProductValidationException(violations);
		}
		return new Product(id, validSku, validName, validDescription, validPrice, now, now);
	}

	private static <T> T collect(Supplier<T> factory, List<Violation> violations) {
		try {
			return factory.get();
		}
		catch (ProductValidationException e) {
			violations.addAll(e.violations());
			return null;
		}
	}

}
