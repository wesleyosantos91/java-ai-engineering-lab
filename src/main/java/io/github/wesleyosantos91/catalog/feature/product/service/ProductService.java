package io.github.wesleyosantos91.catalog.feature.product.service;

import io.github.wesleyosantos91.catalog.feature.product.domain.entity.Product;
import io.github.wesleyosantos91.catalog.feature.product.domain.exception.ProductValidationException;
import io.github.wesleyosantos91.catalog.feature.product.persistence.repository.ProductRepository;
import java.time.Clock;
import java.time.temporal.ChronoUnit;
import java.util.UUID;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Coordena a criação de produtos. A unicidade do SKU é responsabilidade do banco (PRD-001,
 * seção 7): não há consulta prévia, e a violação da restrição vira {@link ProductSkuConflictException}.
 */
@Service
public class ProductService {

	private final ProductRepository repository;
	private final Clock clock;

	public ProductService(ProductRepository repository, Clock clock) {
		this.repository = repository;
		this.clock = clock;
	}

	@Transactional
	public ProductDetails create(CreateProductCommand command) {
		Product product = newProduct(command);
		try {
			repository.insert(product);
		}
		catch (DuplicateKeyException e) {
			throw new ProductSkuConflictException(product.sku().value(), e);
		}
		return ProductDetails.from(product);
	}

	private Product newProduct(CreateProductCommand command) {
		try {
			// Microssegundos: precisão do timestamptz, para que a resposta reflita o valor persistido (D-06).
			return Product.create(UUID.randomUUID(), clock.instant().truncatedTo(ChronoUnit.MICROS), command.sku(),
					command.name(), command.description(), command.price());
		}
		catch (ProductValidationException e) {
			throw new InvalidProductException(e.violations()
				.stream()
				.map(violation -> new ProductFieldError(violation.field(), violation.message()))
				.toList());
		}
	}

}
