package io.github.wesleyosantos91.catalog.feature.product.api.rest.v1.request;

import java.math.BigDecimal;
import tools.jackson.core.JsonParser;
import tools.jackson.databind.DeserializationContext;
import tools.jackson.databind.ValueDeserializer;

/**
 * Aceita somente números JSON e preserva o valor decimal exato do texto, sem passar por
 * {@code double}. Strings como {@code "12.90"} são rejeitadas em vez de convertidas.
 */
public final class JsonNumberOnlyDeserializer extends ValueDeserializer<BigDecimal> {

	@Override
	public BigDecimal deserialize(JsonParser parser, DeserializationContext context) {
		if (!parser.currentToken().isNumeric()) {
			return (BigDecimal) context.handleUnexpectedToken(BigDecimal.class, parser);
		}
		return parser.getDecimalValue();
	}

}
