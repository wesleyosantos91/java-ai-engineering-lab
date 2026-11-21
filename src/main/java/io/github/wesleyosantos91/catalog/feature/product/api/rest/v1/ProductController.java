package io.github.wesleyosantos91.catalog.feature.product.api.rest.v1;

import io.github.wesleyosantos91.catalog.feature.product.api.rest.v1.request.CreateProductRequest;
import io.github.wesleyosantos91.catalog.feature.product.api.rest.v1.response.ProductResponse;
import io.github.wesleyosantos91.catalog.feature.product.service.ProductDetails;
import io.github.wesleyosantos91.catalog.feature.product.service.ProductService;
import java.net.URI;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

/** Contrato HTTP de produtos (PRD-001, seção 5). Sem regras de negócio nem acesso a dados. */
@RestController
@RequestMapping("/api/v1/products")
public class ProductController {

	private final ProductService service;

	public ProductController(ProductService service) {
		this.service = service;
	}

	@PostMapping(consumes = MediaType.APPLICATION_JSON_VALUE)
	public ResponseEntity<ProductResponse> create(@RequestBody CreateProductRequest request) {
		ProductDetails created = service.create(request.toCommand());
		URI location = ServletUriComponentsBuilder.fromCurrentRequestUri()
			.path("/{id}")
			.buildAndExpand(created.id())
			.toUri();
		return ResponseEntity.created(location).body(ProductResponse.from(created));
	}

}
