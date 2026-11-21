package io.github.wesleyosantos91.catalog.feature.product.api.rest.v1.request;

import tools.jackson.core.JsonParser;
import tools.jackson.core.JsonToken;
import tools.jackson.databind.DeserializationContext;
import tools.jackson.databind.ValueDeserializer;

/**
 * Aceita somente strings JSON. Por padrão, o Jackson converte números e booleanos em texto
 * ({@code 123} vira {@code "123"}), o que violaria o PRD-001, seção 6.1. {@code null} continua sendo
 * tratado pelo Jackson antes de chegar aqui.
 */
public final class JsonStringOnlyDeserializer extends ValueDeserializer<String> {

	@Override
	public String deserialize(JsonParser parser, DeserializationContext context) {
		if (parser.currentToken() != JsonToken.VALUE_STRING) {
			return (String) context.handleUnexpectedToken(String.class, parser);
		}
		return parser.getString();
	}

}
