#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
mkdir -p "${ROOT_DIR}/target"
FIXTURE="$(mktemp -d "${ROOT_DIR}/target/harness-check.XXXXXX")/fixture with spaces"
mkdir -p "${FIXTURE}/bin" "${FIXTURE}/src/test/java"
cp -R "${ROOT_DIR}/scripts" "${FIXTURE}/scripts"
touch "${FIXTURE}/pom.xml"
export FIXTURE_TRACE="${FIXTURE}/trace"
export PATH="${FIXTURE}/bin:${PATH}"

cat > "${FIXTURE}/bin/docker" <<'BASH'
#!/usr/bin/env bash
echo docker >> "${FIXTURE_TRACE}"
exit "${MOCK_DOCKER_EXIT:-0}"
BASH
chmod +x "${FIXTURE}/bin/docker"
cat > "${FIXTURE}/mvnw" <<'BASH'
#!/usr/bin/env bash
echo "mvn $*" >> "${FIXTURE_TRACE}"
if [[ "$*" == *'clean compile'* ]]; then exit "${MOCK_BUILD_EXIT:-0}"; fi
if [[ "${MOCK_MAVEN_EXIT:-0}" != 0 ]]; then exit "${MOCK_MAVEN_EXIT}"; fi
if [[ "$*" == *jacoco:check@coverage-check* ]]; then
  mkdir -p target/site/jacoco
  branch='<counter type="BRANCH" missed="0" covered="4"/>'
  [[ "${MOCK_COVERAGE:-pass}" != nobranch ]] || branch=''
  echo "<report><counter type=\"LINE\" missed=\"0\" covered=\"10\"/>${branch}</report>" > target/site/jacoco/jacoco.xml
  exit "${MOCK_COVERAGE_EXIT:-0}"
fi
if [[ "$*" == *mutationCoverage* ]]; then
  mkdir -p target/pit-reports
  mutants="<mutation detected='true' status='KILLED'></mutation>"
  [[ "${MOCK_MUTANTS:-killed}" != none ]] || mutants=''
  echo "<mutations>${mutants}</mutations>" > target/pit-reports/mutations.xml
  exit "${MOCK_PIT_EXIT:-0}"
fi
if [[ "${MOCK_REPORT:-pass}" == missing ]]; then exit 0; fi
reports=surefire-reports
[[ "$*" != *verify* ]] || reports=failsafe-reports
[[ "$*" != *@architecture* ]] || reports=architecture-reports
mkdir -p "target/${reports}"
tests=1; failures=0; errors=0; skipped=0
case "${MOCK_REPORT:-pass}" in
  zero) tests=0 ;;
  skipped) skipped=1 ;;
  partial) tests=2; skipped=1 ;;
  failure) failures=1 ;;
  error) errors=1 ;;
esac
echo "<testsuite tests=\"${tests}\" failures=\"${failures}\" errors=\"${errors}\" skipped=\"${skipped}\"></testsuite>" > "target/${reports}/TEST-Fixture.xml"
BASH

check() {
  local expected="$1" message="$2" script="$3" code=0
  shift 3
  : > "${FIXTURE_TRACE}"
  # Invocar fora da raiz também verifica resolução de caminhos (incluindo espaços).
  (cd "${FIXTURE}/bin" && env "$@" bash "${FIXTURE}/scripts/${script}") > "${FIXTURE}/output" 2>&1 || code=$?
  if [[ "${code}" != "${expected}" ]] || ! grep -Fq "${message}" "${FIXTURE}/output"; then
    cat "${FIXTURE}/output"
    echo "[FAIL] ${script}: esperado exit=${expected}, observado=${code}, texto=${message}" >&2
    exit 1
  fi
  echo "[PASS] ${script}: exit=${code}; ${message}"
}

check 3 '[SKIP]' test-unit.sh
[[ ! -s "${FIXTURE_TRACE}" ]]
check 3 '[SKIP]' test-integration.sh
[[ ! -s "${FIXTURE_TRACE}" ]]
touch "${FIXTURE}/src/test/java/ExampleTest.java" "${FIXTURE}/src/test/java/ExampleIT.java"

check 0 '[PASS] Unitários: 1' test-unit.sh
if grep -Eq 'docker|verify' "${FIXTURE_TRACE}"; then
  echo '[FAIL] Unitários invocaram Docker ou integração.' >&2; exit 1
fi
check 0 '[PASS] Integração: 1' test-integration.sh
grep -q docker "${FIXTURE_TRACE}"
grep -q -- '-DskipUnitTests=true verify' "${FIXTURE_TRACE}"

check 1 'Maven falhou' test-unit.sh MOCK_MAVEN_EXIT=7
check 1 'Maven falhou' test-integration.sh MOCK_MAVEN_EXIT=3
check 1 'relatórios ausentes ou inválidos' test-integration.sh MOCK_REPORT=missing
check 1 'nenhum teste executado' test-unit.sh MOCK_REPORT=zero
check 1 'falhas nos relatórios' test-unit.sh MOCK_REPORT=failure
check 1 'falhas nos relatórios' test-integration.sh MOCK_REPORT=error
check 3 'execução incompleta' test-unit.sh MOCK_REPORT=skipped
check 3 'execução incompleta' test-integration.sh MOCK_REPORT=partial
check 1 'integração NOT RUN' test-integration.sh MOCK_DOCKER_EXIT=1

check 0 'Build=PASS; Unitários=PASS; Integração=PASS' verify.sh
check 7 'Build=FAIL; Unitários=NOT RUN; Integração=NOT RUN' verify.sh MOCK_BUILD_EXIT=7
check 1 'Build=PASS; Unitários=FAIL; Integração=NOT RUN' verify.sh MOCK_MAVEN_EXIT=7
check 0 '[PARCIAL]' verify.sh SKIP_INTEGRATION=1
check 1 'SKIP_INTEGRATION deve ser 0 ou 1' verify.sh SKIP_INTEGRATION=invalid

# Mover a classe de fixture para fora da convenção preserva seu conteúdo.
mv "${FIXTURE}/src/test/java/ExampleTest.java" "${FIXTURE}/src/test/java/ExampleTest.fixture"
check 0 'Build=PASS; Unitários=SKIP; Integração=PASS' verify.sh
grep -Fq '[PARCIAL]' "${FIXTURE}/output"

# Quality gates sem código ou testes elegíveis: SKIP sem chamar Maven.
check 3 'Arquitetura: não existem classes' test-architecture.sh
check 3 'não existe código elegível' test-coverage.sh
check 3 'não existe código de negócio elegível' test-mutation.sh
grep -Fq 'Arquitetura=SKIP; Cobertura=SKIP; Mutação=NOT RUN' <(bash "${FIXTURE}/scripts/verify.sh" 2>&1)

# Testes ArchUnit não tornam a suíte unitária elegível e usam relatórios próprios.
touch "${FIXTURE}/src/test/java/ExampleArchitectureTest.java"
check 3 'Unitários: não existem classes' test-unit.sh
check 0 '[PASS] Arquitetura: 1' test-architecture.sh
grep -q 'surefire:test@architecture' "${FIXTURE_TRACE}"
check 3 'execução incompleta' test-architecture.sh MOCK_REPORT=partial
check 1 'falhas nos relatórios' test-architecture.sh MOCK_REPORT=failure

# Cobertura: código elegível exige dados de execução; LINE sem BRANCH não é aprovação.
domain="${FIXTURE}/src/main/java/io/github/wesleyosantos91/catalog/feature/sample/domain"
mkdir -p "${domain}"
touch "${domain}/Sample.java"
mkdir -p "${FIXTURE}/target"
rm -f "${FIXTURE}/target/"jacoco-*.exec
check 1 'não há dados de execução' test-coverage.sh
echo data > "${FIXTURE}/target/jacoco-unit.exec"
check 0 '[PASS] Cobertura' test-coverage.sh
check 3 'não há branches elegíveis' test-coverage.sh MOCK_COVERAGE=nobranch
check 1 'jacoco:check rejeitou' test-coverage.sh MOCK_COVERAGE_EXIT=1

# Mutação: ausência de mutantes é SKIP; threshold rejeitado é FAIL.
check 0 '[PASS] Mutação' test-mutation.sh
check 3 'nenhum mutante gerado' test-mutation.sh MOCK_MUTANTS=none
check 1 'PIT rejeitou o threshold' test-mutation.sh MOCK_PIT_EXIT=1
echo "[PASS] Contratos do harness verificados com Maven/Docker simulados. Fixtures: ${FIXTURE}"
