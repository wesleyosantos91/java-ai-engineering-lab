package io.github.wesleyosantos91.catalog.feature.product.persistence.repository;

import io.github.wesleyosantos91.catalog.feature.product.domain.entity.Product;
import java.sql.Timestamp;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

/**
 * Acesso à tabela {@code product} com SQL explícito. A unicidade do SKU é garantida pela restrição
 * {@code product_sku_uk}; uma violação chega ao chamador como
 * {@link org.springframework.dao.DuplicateKeyException}.
 */
@Repository
public class ProductRepository {

	private static final String INSERT = """
			INSERT INTO product (id, sku, name, description, price, created_at, updated_at)
			VALUES (:id, :sku, :name, :description, :price, :createdAt, :updatedAt)
			""";

	private final JdbcClient jdbcClient;

	public ProductRepository(JdbcClient jdbcClient) {
		this.jdbcClient = jdbcClient;
	}

	public void insert(Product product) {
		jdbcClient.sql(INSERT)
			.param("id", product.id())
			.param("sku", product.sku().value())
			.param("name", product.name().value())
			.param("description", product.description().value())
			.param("price", product.price().value())
			.param("createdAt", Timestamp.from(product.createdAt()))
			.param("updatedAt", Timestamp.from(product.updatedAt()))
			.update();
	}

}
