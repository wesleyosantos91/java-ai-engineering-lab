package io.github.wesleyosantos91.catalog.architecture;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static com.tngtech.archunit.library.dependencies.SlicesRuleDefinition.slices;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

import com.tngtech.archunit.core.domain.Dependency;
import com.tngtech.archunit.core.domain.JavaClass;
import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.lang.ArchCondition;
import com.tngtech.archunit.lang.ArchRule;
import com.tngtech.archunit.lang.ConditionEvents;
import com.tngtech.archunit.lang.SimpleConditionEvent;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.function.Predicate;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.StreamSupport;
import org.junit.jupiter.api.Test;

/**
 * Regras derivadas de docs/architecture/dependency-rules.md, package-conventions.md e ADR-0001.
 *
 * <p>Uma regra sem classes elegíveis é reportada como ignorada (assumption), nunca como aprovada.
 */
class ArchitectureTest {

	private static final String BASE = "io.github.wesleyosantos91.catalog";
	private static final String FEATURE = BASE + ".feature";
	private static final Pattern FEATURE_LAYER = Pattern.compile(Pattern.quote(FEATURE) + "\\.([^.]+)(?:\\.([^.]+))?.*");

	private static final String DOMAIN = FEATURE + ".*.domain..";
	private static final String API = FEATURE + ".*.api..";
	private static final String PERSISTENCE = FEATURE + ".*.persistence..";
	private static final String MESSAGING = FEATURE + ".*.messaging..";
	private static final String PRODUCER = FEATURE + ".*.messaging..producer..";
	private static final String CLIENT = FEATURE + ".*.client..";
	private static final String SERVICE = FEATURE + ".*.service..";

	private static final JavaClasses CLASSES = new ClassFileImporter()
			.withImportOption(ImportOption.Predefined.DO_NOT_INCLUDE_TESTS)
			.importPackages(BASE);

	@Test
	void domainDoesNotDependOnSpring() {
		checkWhenEligible("domain", inPackage("domain"), noClasses().that().resideInAPackage(DOMAIN)
				.should().dependOnClassesThat().resideInAPackage("org.springframework.."));
	}

	@Test
	void domainDoesNotDependOnHttpOrJdbc() {
		checkWhenEligible("domain", inPackage("domain"), noClasses().that().resideInAPackage(DOMAIN)
				.should().dependOnClassesThat().resideInAnyPackage(
						"jakarta.servlet..", "java.net.http..", "java.sql..", "javax.sql.."));
	}

	@Test
	void domainDoesNotDependOnApiPersistenceMessagingOrClients() {
		checkWhenEligible("domain", inPackage("domain"), noClasses().that().resideInAPackage(DOMAIN)
				.should().dependOnClassesThat().resideInAnyPackage(API, PERSISTENCE, MESSAGING, CLIENT));
	}

	@Test
	void apiDoesNotAccessPersistence() {
		checkWhenEligible("api", inPackage("api"), noClasses().that().resideInAPackage(API)
				.should().dependOnClassesThat().resideInAPackage(PERSISTENCE));
	}

	@Test
	void apiDoesNotExecuteSql() {
		checkWhenEligible("api", inPackage("api"), noClasses().that().resideInAPackage(API)
				.should().dependOnClassesThat().resideInAnyPackage(
						"java.sql..", "javax.sql..", "org.springframework.jdbc.."));
	}

	@Test
	void producersDoNotDependOnControllersOrServices() {
		checkWhenEligible("messaging producer", javaClass -> javaClass.getPackageName().matches(
				Pattern.quote(FEATURE) + "\\.[^.]+\\.messaging\\..*producer(\\..*)?"),
				noClasses().that().resideInAPackage(PRODUCER)
						.should().dependOnClassesThat().resideInAnyPackage(API, SERVICE));
	}

	@Test
	void persistenceTechnologyIsNotJpa() {
		checkWhenEligible("código principal", javaClass -> true, noClasses().that().resideInAPackage(BASE + "..")
				.should().dependOnClassesThat().resideInAnyPackage(
						"jakarta.persistence..", "org.springframework.data.jpa..", "org.hibernate.."));
	}

	@Test
	void featuresAreFreeOfCycles() {
		assumeTrue(features().size() >= 2, "Sem classes elegíveis: são necessárias ao menos duas features.");
		slices().matching(FEATURE + ".(*)..").should().beFreeOfCycles().check(CLASSES);
	}

	@Test
	void featureLayersAreFreeOfCycles() {
		boolean eligible = layersByFeature().values().stream().anyMatch(layers -> layers.size() >= 2);
		assumeTrue(eligible, "Sem classes elegíveis: nenhuma feature possui ao menos dois packages internos.");
		slices().matching(FEATURE + ".(*).(*)..").should().beFreeOfCycles().check(CLASSES);
	}

	@Test
	void featuresDoNotAccessPersistenceOfOtherFeatures() {
		assumeTrue(features().size() >= 2 && stream().anyMatch(inPackage("persistence")),
				"Sem classes elegíveis: são necessárias duas features e ao menos uma classe de persistence.");
		classes().that().resideInAPackage(FEATURE + "..").should(notDependOnPersistenceOfAnotherFeature())
				.check(CLASSES);
	}

	private static void checkWhenEligible(String scope, Predicate<JavaClass> eligible, ArchRule rule) {
		assumeTrue(stream().anyMatch(eligible), "Sem classes elegíveis em " + scope + ".");
		rule.check(CLASSES);
	}

	private static Predicate<JavaClass> inPackage(String layer) {
		return javaClass -> layerOf(javaClass.getPackageName()).filter(layer::equals).isPresent();
	}

	private static java.util.stream.Stream<JavaClass> stream() {
		return StreamSupport.stream(CLASSES.spliterator(), false);
	}

	private static Set<String> features() {
		return stream().map(javaClass -> featureOf(javaClass.getPackageName()))
				.flatMap(Optional::stream).collect(Collectors.toSet());
	}

	private static Map<String, Set<String>> layersByFeature() {
		return stream().filter(javaClass -> layerOf(javaClass.getPackageName()).isPresent())
				.collect(Collectors.groupingBy(javaClass -> featureOf(javaClass.getPackageName()).orElseThrow(),
						Collectors.mapping(javaClass -> layerOf(javaClass.getPackageName()).orElseThrow(),
								Collectors.toSet())));
	}

	private static Optional<String> featureOf(String packageName) {
		Matcher matcher = FEATURE_LAYER.matcher(packageName);
		return matcher.matches() ? Optional.of(matcher.group(1)) : Optional.empty();
	}

	private static Optional<String> layerOf(String packageName) {
		Matcher matcher = FEATURE_LAYER.matcher(packageName);
		return matcher.matches() ? Optional.ofNullable(matcher.group(2)) : Optional.empty();
	}

	private static ArchCondition<JavaClass> notDependOnPersistenceOfAnotherFeature() {
		return new ArchCondition<>("not depend on the persistence of another feature") {
			@Override
			public void check(JavaClass origin, ConditionEvents events) {
				Optional<String> originFeature = featureOf(origin.getPackageName());
				for (Dependency dependency : origin.getDirectDependenciesFromSelf()) {
					String targetPackage = dependency.getTargetClass().getPackageName();
					Optional<String> targetFeature = featureOf(targetPackage);
					boolean otherFeaturePersistence = targetFeature.isPresent()
							&& !targetFeature.equals(originFeature)
							&& layerOf(targetPackage).filter("persistence"::equals).isPresent();
					if (otherFeaturePersistence) {
						events.add(SimpleConditionEvent.violated(dependency, dependency.getDescription()));
					}
				}
			}
		};
	}

}
