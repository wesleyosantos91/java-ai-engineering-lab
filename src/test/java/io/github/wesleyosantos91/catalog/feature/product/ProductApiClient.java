package io.github.wesleyosantos91.catalog.feature.product;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

/** Cliente HTTP real (JDK) para os testes de integração da API de produtos. */
final class ProductApiClient {

	private final HttpClient http = HttpClient.newHttpClient();
	private final URI products;

	ProductApiClient(int port) {
		this.products = URI.create("http://localhost:" + port + "/api/v1/products");
	}

	HttpResponse<String> create(String json) {
		return create(json, "application/json");
	}

	HttpResponse<String> create(String json, String accept) {
		HttpRequest request = HttpRequest.newBuilder(products)
			.header("Content-Type", "application/json")
			.header("Accept", accept)
			.POST(HttpRequest.BodyPublishers.ofString(json))
			.build();
		try {
			return http.send(request, HttpResponse.BodyHandlers.ofString());
		}
		catch (IOException e) {
			throw new UncheckedIOException(e);
		}
		catch (InterruptedException e) {
			Thread.currentThread().interrupt();
			throw new IllegalStateException(e);
		}
	}

	URI productsUri() {
		return products;
	}

}
