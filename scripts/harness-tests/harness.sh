#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
mkdir -p "${ROOT_DIR}/target"
FIXTURE="$(mktemp -d "${ROOT_DIR}/target/harness-check.XXXXXX")/fixture with spaces"
mkdir -p "${FIXTURE}/bin" "${FIXTURE}/src/test/java"
cp -R "${ROOT_DIR}/scripts" "${FIXTURE}/scripts"
touch "${FIXTURE}/pom.xml"
# O check de configuração de agentes tem teste próprio (harness-tests/agent-config.sh); aqui é simulado.
cat > "${FIXTURE}/scripts/agents/check-config.sh" <<'BASH'
#!/usr/bin/env bash
echo agents >> "${FIXTURE_TRACE}"
exit "${MOCK_AGENTS_EXIT:-0}"
BASH
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
tests=1; failures=0; errors=0; skipped=0; cases=''
na='<testcase><skipped><![CDATA[TestAbortedException: Assumption failed: [N/A] Sem classes]]></skipped></testcase>'
case "${MOCK_REPORT:-pass}" in
  zero) tests=0 ;;
  skipped) skipped=1 ;;
  partial) tests=2; skipped=1 ;;
  failure) failures=1 ;;
  error) errors=1 ;;
  na) tests=3; skipped=2; cases="${na}${na}" ;;
  allna) tests=2; skipped=2; cases="${na}${na}" ;;
  mixed) tests=3; skipped=2; cases="${na}" ;;
esac
echo "<testsuite tests=\"${tests}\" failures=\"${failures}\" errors=\"${errors}\" skipped=\"${skipped}\">${cases}</testsuite>" > "target/${reports}/TEST-Fixture.xml"
BASH

check() {
  local expected="$1" message="$2" script="$3" code=0 vars=() args=()
  shift 3
  # VAR=valor vão para o env; argumentos do script vêm depois de "--" (ver LL-0003).
  while (( $# )); do
    if [[ "$1" == -- ]]; then shift; args=("$@"); break; fi
    vars+=("$1"); shift
  done
  : > "${FIXTURE_TRACE}"
  # Invocar fora da raiz também verifica resolução de caminhos (incluindo espaços).
  (cd "${FIXTURE}/bin" && env "${vars[@]}" bash "${FIXTURE}/scripts/${script}" "${args[@]}") > "${FIXTURE}/output" 2>&1 || code=$?
  if [[ "${code}" != "${expected}" ]] || ! grep -Fq "${message}" "${FIXTURE}/output"; then
    cat "${FIXTURE}/output"
    echo "[FAIL] ${script}: esperado exit=${expected}, observado=${code}, texto=${message}" >&2
    exit 1
  fi
  echo "[PASS] ${script}: exit=${code}; ${message}"
}

check 3 '[SKIP]' test/unit.sh
[[ ! -s "${FIXTURE_TRACE}" ]]
check 3 '[SKIP]' test/integration.sh
[[ ! -s "${FIXTURE_TRACE}" ]]
touch "${FIXTURE}/src/test/java/ExampleTest.java" "${FIXTURE}/src/test/java/ExampleIT.java"

check 0 '[PASS] Unitários: 1' test/unit.sh
if grep -Eq 'docker|verify' "${FIXTURE_TRACE}"; then
  echo '[FAIL] Unitários invocaram Docker ou integração.' >&2; exit 1
fi
check 0 '[PASS] Integração: 1' test/integration.sh
grep -q docker "${FIXTURE_TRACE}"
grep -q -- '-DskipUnitTests=true verify' "${FIXTURE_TRACE}"

check 1 'Maven falhou' test/unit.sh MOCK_MAVEN_EXIT=7
check 1 'Maven falhou' test/integration.sh MOCK_MAVEN_EXIT=3
check 1 'relatórios ausentes ou inválidos' test/integration.sh MOCK_REPORT=missing
check 1 'nenhum teste executado' test/unit.sh MOCK_REPORT=zero
check 1 'falhas nos relatórios' test/unit.sh MOCK_REPORT=failure
check 1 'falhas nos relatórios' test/integration.sh MOCK_REPORT=error
check 3 'execução incompleta' test/unit.sh MOCK_REPORT=skipped
check 3 'execução incompleta' test/integration.sh MOCK_REPORT=partial
check 1 'integração NOT RUN' test/integration.sh MOCK_DOCKER_EXIT=1

check 0 'Agentes=PASS; Build=PASS; Unitários=PASS; Arquitetura=SKIP; Integração=PASS' verify.sh
check 7 'Build=FAIL; Unitários=NOT RUN; Arquitetura=NOT RUN; Integração=NOT RUN' verify.sh MOCK_BUILD_EXIT=7
check 1 'Agentes=FAIL; Build=NOT RUN; Unitários=NOT RUN' verify.sh MOCK_AGENTS_EXIT=1
if grep -q 'mvn' "${FIXTURE_TRACE}"; then
  echo '[FAIL] verify.sh executou Maven após falha da configuração de agentes.' >&2; exit 1
fi
check 1 'Build=PASS; Unitários=FAIL; Arquitetura=NOT RUN; Integração=NOT RUN' verify.sh MOCK_MAVEN_EXIT=7
check 0 '[PARCIAL]' verify.sh SKIP_INTEGRATION=1
check 1 'SKIP_INTEGRATION deve ser 0 ou 1' verify.sh SKIP_INTEGRATION=invalid

# Mover a classe de fixture para fora da convenção preserva seu conteúdo.
mv "${FIXTURE}/src/test/java/ExampleTest.java" "${FIXTURE}/src/test/java/ExampleTest.fixture"
check 0 'Build=PASS; Unitários=SKIP; Arquitetura=SKIP; Integração=PASS' verify.sh
grep -Fq '[PARCIAL]' "${FIXTURE}/output"

# Quality gates sem código ou testes elegíveis: SKIP sem chamar Maven.
check 3 'Arquitetura: não existem classes' test/architecture.sh
check 3 'não existe código elegível' quality/coverage.sh
check 3 'não existe código de negócio elegível' quality/mutation.sh
grep -Fq 'Arquitetura=SKIP; Integração=PASS; Cobertura=SKIP; Mutação=NOT RUN' <(bash "${FIXTURE}/scripts/verify.sh" 2>&1)

# Testes ArchUnit não tornam a suíte unitária elegível e usam relatórios próprios.
touch "${FIXTURE}/src/test/java/ExampleArchitectureTest.java"
check 3 'Unitários: não existem classes' test/unit.sh
check 0 '[PASS] Arquitetura: 1' test/architecture.sh
grep -q 'surefire:test@architecture' "${FIXTURE_TRACE}"
check 3 'execução incompleta' test/architecture.sh MOCK_REPORT=partial
check 1 'falhas nos relatórios' test/architecture.sh MOCK_REPORT=failure
# Regras não aplicáveis ([N/A]) não são SKIP, mas exigem ao menos uma regra executada.
check 0 '1 teste(s); 2 não aplicável(is) (N/A)' test/architecture.sh MOCK_REPORT=na
check 3 'nenhum teste aplicável executado (N/A=2)' test/architecture.sh MOCK_REPORT=allna
check 3 'execução incompleta (1 ignorado(s), N/A=1)' test/architecture.sh MOCK_REPORT=mixed
# O marcador vale só para a arquitetura: nas demais suítes, todo ignorado continua SKIP.
check 3 'execução incompleta (2 ignorado(s), N/A=0)' test/integration.sh MOCK_REPORT=na

# Cobertura: código elegível exige dados de execução; LINE sem BRANCH não é aprovação.
domain="${FIXTURE}/src/main/java/io/github/wesleyosantos91/catalog/feature/sample/domain"
mkdir -p "${domain}"
touch "${domain}/Sample.java"
mkdir -p "${FIXTURE}/target"
rm -f "${FIXTURE}/target/"jacoco-*.exec
check 1 'não há dados de execução' quality/coverage.sh
echo data > "${FIXTURE}/target/jacoco-unit.exec"
check 0 '[PASS] Cobertura' quality/coverage.sh
check 3 'não há branches elegíveis' quality/coverage.sh MOCK_COVERAGE=nobranch
check 1 'jacoco:check rejeitou' quality/coverage.sh MOCK_COVERAGE_EXIT=1

# Mutação: ausência de mutantes é SKIP; threshold rejeitado é FAIL.
check 0 '[PASS] Mutação' quality/mutation.sh
check 3 'nenhum mutante gerado' quality/mutation.sh MOCK_MUTANTS=none
check 1 'PIT rejeitou o threshold' quality/mutation.sh MOCK_PIT_EXIT=1
# Performance: smoke k6 com k6 e curl simulados; a aplicação real não é necessária.
mkdir -p "${FIXTURE}/performance/k6"
touch "${FIXTURE}/performance/k6/smoke.js"
cat > "${FIXTURE}/bin/curl" <<'BASH'
#!/usr/bin/env bash
echo "curl $*" >> "${FIXTURE_TRACE}"
exit "${MOCK_CURL_EXIT:-0}"
BASH
cat > "${FIXTURE}/bin/k6" <<'BASH'
#!/usr/bin/env bash
echo "k6 $*" >> "${FIXTURE_TRACE}"
while (( $# )); do [[ "$1" == --summary-export ]] && { echo '{}' > "$2"; break; }; shift; done
exit "${MOCK_K6_EXIT:-0}"
BASH
chmod +x "${FIXTURE}/bin/curl" "${FIXTURE}/bin/k6"
check 1 'k6 não encontrado' performance/smoke.sh PATH=/usr/bin:/bin
check 1 'aplicação inacessível' performance/smoke.sh MOCK_CURL_EXIT=7
check 1 'threshold violado' performance/smoke.sh MOCK_K6_EXIT=99
check 0 '[PASS] Performance' performance/smoke.sh
grep -q -- '--summary-export target/performance/smoke-summary.json' "${FIXTURE_TRACE}"

# Segredos: sem gitleaks e sem Docker é SKIP; achados e erros do gitleaks são FAIL.
cp "${ROOT_DIR}/.gitleaks.toml" "${FIXTURE}/.gitleaks.toml"
check 3 'gitleaks e Docker indisponíveis' security/scan-secrets.sh PATH=/usr/bin:/bin
cat > "${FIXTURE}/bin/gitleaks" <<'BASH'
#!/usr/bin/env bash
echo "gitleaks $*" >> "${FIXTURE_TRACE}"
exit "${MOCK_GITLEAKS_EXIT:-0}"
BASH
chmod +x "${FIXTURE}/bin/gitleaks"
check 0 '[PASS] Segredos' security/scan-secrets.sh
grep -q -- 'gitleaks git . --config ./.gitleaks.toml --redact' "${FIXTURE_TRACE}"
grep -q -- 'gitleaks dir .' "${FIXTURE_TRACE}"
check 0 'diff preparado' security/scan-secrets.sh -- --staged
grep -q -- '--pre-commit --staged' "${FIXTURE_TRACE}"
check 1 'possíveis segredos encontrados' security/scan-secrets.sh MOCK_GITLEAKS_EXIT=1
check 1 'gitleaks falhou (exit 2)' security/scan-secrets.sh MOCK_GITLEAKS_EXIT=2

echo "[PASS] Contratos do harness verificados com Maven/Docker simulados. Fixtures: ${FIXTURE}"
