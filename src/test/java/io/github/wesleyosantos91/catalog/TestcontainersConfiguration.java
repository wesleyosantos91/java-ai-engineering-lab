package io.github.wesleyosantos91.catalog;

import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.context.annotation.Bean;
import org.testcontainers.postgresql.PostgreSQLContainer;
import org.testcontainers.utility.DockerImageName;

@TestConfiguration(proxyBeanMethods = false)
class TestcontainersConfiguration {

	@Bean
	@ServiceConnection
	PostgreSQLContainer postgresContainer() {
		// Official postgres:18.2, pinned by digest; Testcontainers 2.0.x needs explicit compatibility.
		return new PostgreSQLContainer(DockerImageName.parse(
				"postgres@sha256:a688ae5c99f86c1424e046ace0de890608cc0ddb5ec8ef72a6ff8305fdc8f4d2")
				.asCompatibleSubstituteFor("postgres"));
	}

}
