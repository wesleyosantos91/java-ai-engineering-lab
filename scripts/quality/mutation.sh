#!/usr/bin/env bash
# Quality gate PIT: mutation score >= 90% sobre domain e service das features.
# Execução explícita, fora do verify.sh, por ser mais lenta. Executa somente testes *Test.
# Retornos: 0 = PASS, 3 = SKIP (sem código elegível ou sem mutantes), 1 = FAIL.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
source "${SCRIPT_DIR}/../lib/app.sh" || exit 1
REPORT_DIR="${APP_ROOT}/target/pit-reports"

require_maven_project || exit 1

source "${SCRIPT_DIR}/../lib/pom.sh"
pom_has 'pitest-maven' && pom_has '<app.basePath>' ||
  gate_not_configured Mutação 'PIT (pitest-maven e propriedade app.basePath)'
# Mesmo pacote base de targetClasses no pitest-maven (app.basePath).
BASE_PATH="$(pom_property app.basePath)" || exit 1
FEATURE_DIR="${APP_ROOT}/src/main/java/${BASE_PATH}/feature"

# Mesmo escopo de targetClasses do pitest-maven: feature/*/domain e feature/*/service.
if [[ ! -d "${FEATURE_DIR}" ]] ||
   ! find "${FEATURE_DIR}" -type f -name '*.java' ! -name 'package-info.java' \
     \( -path '*/domain/*' -o -path '*/service/*' \) -print -quit | grep -q .; then
  echo "[SKIP] Mutação: não existe código de negócio elegível (feature/*/domain ou feature/*/service)."
  exit 3
fi

rm -rf "${REPORT_DIR}"
cd "${APP_ROOT}"
echo "[INFO] Mutação: executando PIT; meta mutation score >= 90%."
code=0
bash ./mvnw --batch-mode --no-transfer-progress \
  test-compile org.pitest:pitest-maven:mutationCoverage || code=$?

report="${REPORT_DIR}/mutations.xml"
[[ -f "${report}" ]] || {
  echo "[FAIL] Mutação: relatório ${report} ausente; medição não comprovada (exit Maven=${code})." >&2; exit 1;
}
count() { { grep -oE "$1" "${report}" || true; } | wc -l | tr -d ' '; }
total="$(count "<mutation [^>]*detected=['\"](true|false)['\"]")"
detected="$(count "<mutation [^>]*detected=['\"]true['\"]")"
survived="$(count "status=['\"]SURVIVED['\"]")"
no_coverage="$(count "status=['\"]NO_COVERAGE['\"]")"
echo "[INFO] Mutação: mutantes=${total}, detectados=${detected}, sobreviventes=${survived}, sem cobertura=${no_coverage}."
echo "[INFO] Relatórios: ${APP_PREFIX}target/pit-reports/index.html e target/pit-reports/mutations.xml"

if (( code != 0 )); then
  echo "[FAIL] Mutação: PIT rejeitou o threshold ou Maven falhou." >&2
  exit 1
fi
if (( total == 0 )); then
  echo "[SKIP] Mutação: nenhum mutante gerado; score não comprovado."
  exit 3
fi
echo "[PASS] Mutação: score $(awk -v d="${detected}" -v t="${total}" 'BEGIN { printf "%.2f%%", 100 * d / t }') atende à meta."
