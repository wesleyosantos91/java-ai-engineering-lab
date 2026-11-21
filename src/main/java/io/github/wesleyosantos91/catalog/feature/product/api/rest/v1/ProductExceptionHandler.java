package io.github.wesleyosantos91.catalog.feature.product.api.rest.v1;

import io.github.wesleyosantos91.catalog.feature.product.api.rest.v1.response.FieldErrorResponse;
import io.github.wesleyosantos91.catalog.feature.product.service.InvalidProductException;
import io.github.wesleyosantos91.catalog.feature.product.service.ProductSkuConflictException;
import java.net.URI;
import java.util.List;
import java.util.Optional;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.ServletWebRequest;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;
import tools.jackson.core.JacksonException;

/**
 * Traduz falhas da API de produtos para {@code ProblemDetail} (RFC 9457) com a extensão {@code code}
 * (PRD-001, seção 6.3). Nenhuma mensagem interna (SQL, Jackson, stack trace) chega ao cliente.
 */
@RestControllerAdvice(assignableTypes = ProductController.class)
class ProductExceptionHandler extends ResponseEntityExceptionHandler {

	static final String VALIDATION_FAILED = "VALIDATION_FAILED";
	static final String PRODUCT_SKU_CONFLICT = "PRODUCT_SKU_CONFLICT";

	@ExceptionHandler(InvalidProductException.class)
	ResponseEntity<ProblemDetail> handleInvalidProduct(InvalidProductException ex, WebRequest request) {
		List<FieldErrorResponse> errors = ex.errors()
			.stream()
			.map(error -> new FieldErrorResponse(error.field(), error.message()))
			.toList();
		return problem(validationProblem(errors), request);
	}

	@ExceptionHandler(ProductSkuConflictException.class)
	ResponseEntity<ProblemDetail> handleSkuConflict(ProductSkuConflictException ex, WebRequest request) {
		ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.CONFLICT,
				"A product with SKU '" + ex.sku() + "' already exists.");
		problem.setTitle("Product SKU conflict");
		problem.setProperty("code", PRODUCT_SKU_CONFLICT);
		return problem(problem, request);
	}

	/** Corpo ausente, JSON malformado, tipo incompatível ou propriedade desconhecida. */
	@Override
	protected ResponseEntity<Object> handleHttpMessageNotReadable(HttpMessageNotReadableException ex,
			HttpHeaders headers, HttpStatusCode status, WebRequest request) {
		List<FieldErrorResponse> errors = fieldOf(ex)
			.map(field -> List.of(new FieldErrorResponse(field, "invalid or not allowed value")))
			.orElse(List.of());
		ProblemDetail problem = validationProblem(errors);
		problem.setInstance(instance(request));
		return ResponseEntity.badRequest().body(problem);
	}

	private static ProblemDetail validationProblem(List<FieldErrorResponse> errors) {
		ProblemDetail problem = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST,
				"The request body is invalid; see 'errors' for the affected fields.");
		problem.setTitle("Validation failed");
		problem.setProperty("code", VALIDATION_FAILED);
		if (!errors.isEmpty()) {
			problem.setProperty("errors", errors);
		}
		return problem;
	}

	private static ResponseEntity<ProblemDetail> problem(ProblemDetail problem, WebRequest request) {
		problem.setInstance(instance(request));
		return ResponseEntity.status(problem.getStatus()).body(problem);
	}

	private static URI instance(WebRequest request) {
		return URI.create(((ServletWebRequest) request).getRequest().getRequestURI());
	}

	/** Nome do campo JSON que causou a falha de leitura, quando o Jackson o identifica. */
	private static Optional<String> fieldOf(HttpMessageNotReadableException ex) {
		for (Throwable cause = ex.getCause(); cause != null; cause = cause.getCause()) {
			if (cause instanceof JacksonException jackson && !jackson.getPath().isEmpty()) {
				return Optional.ofNullable(jackson.getPath().getLast().getPropertyName());
			}
		}
		return Optional.empty();
	}

}
