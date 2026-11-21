#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
mkdir -p "${ROOT_DIR}/target"
FIXTURE="$(mktemp -d "${ROOT_DIR}/target/maven-isolation.XXXXXX")/project with spaces"
mkdir -p "${FIXTURE}"
cp "${ROOT_DIR}/pom.xml" "${ROOT_DIR}/mvnw" "${FIXTURE}/"
cp -R "${ROOT_DIR}/.mvn" "${ROOT_DIR}/src" "${FIXTURE}/"
cat > "${FIXTURE}/src/test/java/io/github/wesleyosantos91/catalog/SuiteIsolationTest.java" <<'JAVA'
package io.github.wesleyosantos91.catalog;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.lang.management.ManagementFactory;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import org.junit.jupiter.api.Test;

class SuiteIsolationTest {
    static final class Dependency {
        String value() { return "real"; }
    }

    @Test
    void usesStartupAgentWithoutDocker() throws Exception {
        assertThat(ManagementFactory.getRuntimeMXBean().getInputArguments())
                .anyMatch(arg -> arg.startsWith("-javaagent:") && arg.contains("mockito-core"));
        Dependency dependency = mock(Dependency.class);
        when(dependency.value()).thenReturn("mocked");
        assertThat(dependency.value()).isEqualTo("mocked");
        Files.writeString(Path.of("target/unit-runs"), "unit\n",
                StandardOpenOption.CREATE, StandardOpenOption.APPEND);
    }
}
JAVA

cd "${FIXTURE}"
# Docker deliberadamente inacessível apenas nesta chamada; não parar o Docker Desktop.
DOCKER_HOST=tcp://127.0.0.1:1 bash ./mvnw --batch-mode --no-transfer-progress \
  '-DargLine=-XX:-EnableDynamicAgentLoading' test > unit.log 2>&1 || { cat unit.log; exit 1; }
[[ -f target/surefire-reports/TEST-io.github.wesleyosantos91.catalog.SuiteIsolationTest.xml ]]
[[ ! -d target/failsafe-reports ]]
if grep -q 'org.testcontainers' unit.log; then
  echo '[FAIL] Unitários inicializaram Testcontainers.' >&2; exit 1
fi
echo '[PASS] Surefire: um teste com Mockito inline, attach dinâmico desativado e Docker inacessível; nenhum IT.'

bash ./mvnw --batch-mode --no-transfer-progress -DskipUnitTests=true \
  '-DargLine=-XX:-EnableDynamicAgentLoading' verify > integration.log 2>&1 || { cat integration.log; exit 1; }
[[ "$(wc -l < target/unit-runs)" -eq 1 ]]
grep -q 'tests="1".*errors="0".*skipped="0".*failures="0"' \
  target/failsafe-reports/TEST-io.github.wesleyosantos91.catalog.JavaAiEngineeringLabApplicationIT.xml
if grep -Eq 'self-attaching|agent has been loaded dynamically' unit.log integration.log; then
  echo '[FAIL] Aviso de attach dinâmico detectado.' >&2; exit 1
fi
echo '[PASS] Failsafe: contexto e PostgreSQL 18.2; unitário não repetido; sem attach dinâmico.'

# Falha deliberada apenas na cópia isolada: deve chegar a failsafe:verify e retornar erro.
cat > src/test/java/io/github/wesleyosantos91/catalog/FailureIT.java <<'JAVA'
package io.github.wesleyosantos91.catalog;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.fail;
class FailureIT {
    @Test void failsDeliberately() { fail("Intentional infrastructure validation failure"); }
}
JAVA
code=0
bash ./mvnw --batch-mode --no-transfer-progress -DskipUnitTests=true \
  -Dit.test=FailureIT verify > failure.log 2>&1 || code=$?
[[ "${code}" -ne 0 ]]
grep -q 'Intentional infrastructure validation failure' failure.log
grep -q 'failsafe:3.5.6:verify' failure.log
echo "[PASS] Falha deliberada de IT rejeitada pelo Failsafe verify (exit=${code})."
echo "[INFO] Relatórios e logs reais preservados na fixture: ${FIXTURE}"
