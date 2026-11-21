package io.github.wesleyosantos91.catalog.shared.configuration;

import java.time.Clock;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Relógio único da aplicação, em UTC (PRD-001, seção 4.4); substituível em testes. */
@Configuration(proxyBeanMethods = false)
public class TimeConfiguration {

	@Bean
	Clock clock() {
		return Clock.systemUTC();
	}

}
