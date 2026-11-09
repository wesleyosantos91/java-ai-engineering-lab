package io.github.wesleyosantos91.catalog;

import org.springframework.boot.SpringApplication;

public class TestJavaAiEngineeringLabApplication {

	public static void main(String[] args) {
		SpringApplication.from(JavaAiEngineeringLabApplication::main).with(TestcontainersConfiguration.class).run(args);
	}

}
