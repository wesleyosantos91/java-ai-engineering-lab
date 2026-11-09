#!/usr/bin/env bash
# Prova, com Maven real em cópia temporária, que ArchUnit, JaCoCo e PIT rejeitam violações
# e aprovam código conforme. Classes de exemplo existem apenas na cópia; nada é gravado em src/.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
mkdir -p "${ROOT_DIR}/target"
FIXTURE="$(mktemp -d "${ROOT_DIR}/target/quality-gates.XXXXXX")/project with spaces"
mkdir -p "${FIXTURE}"
cp "${ROOT_DIR}/pom.xml" "${ROOT_DIR}/mvnw" "${FIXTURE}/"
cp -R "${ROOT_DIR}/.mvn" "${ROOT_DIR}/src" "${ROOT_DIR}/scripts" "${FIXTURE}/"

PKG=io/github/wesleyosantos91/catalog/feature/sample
MAIN="${FIXTURE}/src/main/java/${PKG}"
TEST="${FIXTURE}/src/test/java/${PKG}"
mkdir -p "${MAIN}/domain" "${MAIN}/service" "${TEST}/domain" "${TEST}/service"

expect() {
  local expected="$1" message="$2" script="$3" code=0 log
  log="${FIXTURE}/$(basename "${script}" .sh)-$(date +%s%N).log"
  bash "${FIXTURE}/scripts/${script}" > "${log}" 2>&1 || code=$?
  if [[ "${code}" != "${expected}" ]] || ! grep -Fq "${message}" "${log}"; then
    tail -n 60 "${log}"
    echo "[FAIL] ${script}: esperado exit=${expected} e '${message}'; observado exit=${code}. Log: ${log}" >&2
    exit 1
  fi
  echo "[PASS] ${script}: exit=${code}; ${message}"
  LAST_LOG="${log}"
}

cat > "${MAIN}/domain/PriceRule.java" <<'JAVA'
package io.github.wesleyosantos91.catalog.feature.sample.domain;

public final class PriceRule {
    public static final long MAX_CENTS = 100_000_000L;

    public boolean isValid(long cents) {
        if (cents <= 0) {
            return false;
        }
        return cents <= MAX_CENTS;
    }
}
JAVA
cat > "${MAIN}/service/PriceService.java" <<'JAVA'
package io.github.wesleyosantos91.catalog.feature.sample.service;

import io.github.wesleyosantos91.catalog.feature.sample.domain.PriceRule;

public class PriceService {
    private final PriceRule rule;

    public PriceService(PriceRule rule) {
        this.rule = rule;
    }

    public String classify(long cents) {
        return rule.isValid(cents) ? "VALID" : "INVALID";
    }
}
JAVA
# Registra os argumentos da JVM de teste para comprovar a composição dos agents.
cat > "${TEST}/AgentCompositionTest.java" <<'JAVA'
package io.github.wesleyosantos91.catalog.feature.sample;

import static org.assertj.core.api.Assertions.assertThat;

import java.lang.management.ManagementFactory;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;

class AgentCompositionTest {
    @Test
    void mockitoAgentIsLoadedAtStartup() throws Exception {
        var arguments = ManagementFactory.getRuntimeMXBean().getInputArguments();
        Files.writeString(Path.of("target", "jvm-arguments.txt"), String.join("\n", arguments));
        assertThat(arguments).anyMatch(arg -> arg.startsWith("-javaagent:") && arg.contains("mockito-core"));
    }
}
JAVA

echo "[INFO] 1/3 ArchUnit"
cat > "${MAIN}/domain/SpringCoupledRule.java" <<'JAVA'
package io.github.wesleyosantos91.catalog.feature.sample.domain;

import org.springframework.util.Assert;

public final class SpringCoupledRule {
    public void requirePositive(long value) {
        Assert.isTrue(value > 0, "value must be positive");
    }
}
JAVA
expect 1 'Arquitetura: Maven falhou' test-architecture.sh
grep -q 'domainDoesNotDependOnSpring' "${LAST_LOG}"
grep -q 'SpringCoupledRule' "${FIXTURE}/target/architecture-reports/"*.txt
echo "[PASS] Violação domain -> Spring identificada em SpringCoupledRule."
rm "${MAIN}/domain/SpringCoupledRule.java"
expect 3 'execução incompleta' test-architecture.sh
read -r total skipped < <(grep -oE 'total=[0-9]+, failures=0, errors=0, skipped=[0-9]+' "${LAST_LOG}" |
  sed -E 's/total=([0-9]+).*skipped=([0-9]+)/\1 \2/')
(( total > skipped )) || { echo "[FAIL] Regras de domain não foram executadas." >&2; exit 1; }
echo "[PASS] Código conforme: $((total - skipped)) regra(s) executada(s) e aprovada(s); ${skipped} sem classes elegíveis (SKIP)."

echo "[INFO] 2/3 JaCoCo e 3/3 PIT com testes insuficientes"
cat > "${TEST}/domain/PriceRuleTest.java" <<'JAVA'
package io.github.wesleyosantos91.catalog.feature.sample.domain;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class PriceRuleTest {
    @Test
    void acceptsTypicalPrice() {
        assertThat(new PriceRule().isValid(500)).isTrue();
    }
}
JAVA
expect 0 '[PASS] Unitários' test-unit.sh
grep -q 'org.jacoco.agent' "${FIXTURE}/target/jvm-arguments.txt"
grep -q 'mockito-core' "${FIXTURE}/target/jvm-arguments.txt"
echo "[PASS] JVM unitária com agents JaCoCo e Mockito simultâneos."
expect 1 'jacoco:check rejeitou' test-coverage.sh
expect 1 'PIT rejeitou o threshold' test-mutation.sh
grep -Eq 'sobreviventes=[1-9]|sem cobertura=[1-9]' "${LAST_LOG}"

echo "[INFO] 2/3 JaCoCo e 3/3 PIT com testes comportamentais completos"
cat > "${TEST}/domain/PriceRuleTest.java" <<'JAVA'
package io.github.wesleyosantos91.catalog.feature.sample.domain;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

class PriceRuleTest {
    @ParameterizedTest
    @CsvSource({"-1,false", "0,false", "1,true", "100000000,true", "100000001,false"})
    void validatesPriceLimits(long cents, boolean expected) {
        assertThat(new PriceRule().isValid(cents)).isEqualTo(expected);
    }
}
JAVA
cat > "${TEST}/service/PriceServiceTest.java" <<'JAVA'
package io.github.wesleyosantos91.catalog.feature.sample.service;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import io.github.wesleyosantos91.catalog.feature.sample.domain.PriceRule;
import org.junit.jupiter.api.Test;

class PriceServiceTest {
    // PriceRule é final: exige o mock maker inline carregado pelo agent do Mockito.
    private final PriceRule rule = mock(PriceRule.class);
    private final PriceService service = new PriceService(rule);

    @Test
    void classifiesValidPrice() {
        when(rule.isValid(10)).thenReturn(true);
        assertThat(service.classify(10)).isEqualTo("VALID");
    }

    @Test
    void classifiesInvalidPrice() {
        when(rule.isValid(10)).thenReturn(false);
        assertThat(service.classify(10)).isEqualTo("INVALID");
    }
}
JAVA
expect 0 '[PASS] Unitários' test-unit.sh
expect 0 '[PASS] Cobertura' test-coverage.sh
expect 0 '[PASS] Mutação' test-mutation.sh
grep -E '^\[INFO\] Mutação: mutantes=' "${LAST_LOG}"
echo "[PASS] Quality gates rejeitam violações e aprovam código conforme. Fixture: ${FIXTURE}"
