package io.github.wesleyosantos91.catalog.feature.product.domain.valueobject;

import io.github.wesleyosantos91.catalog.feature.product.domain.exception.ProductValidationException;
import java.util.Locale;
import java.util.regex.Pattern;

/**
 * SKU normalizado (PRD-001, seção 4.1): sem espaços externos, em maiúsculas, de 3 a 32
 * caracteres entre A-Z, 0-9, hífen e underscore, iniciando por letra ou número.
 */
public record Sku(String value) {

	private static final Pattern FORMAT = Pattern.compile("[A-Z0-9][A-Z0-9_-]{2,31}");

	public Sku {
		if (value == null || !FORMAT.matcher(value).matches()) {
			throw ProductValidationException.of("sku",
					"must have 3 to 32 characters (A-Z, 0-9, '-' or '_') and start with a letter or digit");
		}
	}

	public static Sku of(String raw) {
		return new Sku(raw == null ? null : raw.strip().toUpperCase(Locale.ROOT));
	}

}
