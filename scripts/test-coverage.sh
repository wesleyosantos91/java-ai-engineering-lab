#!/usr/bin/env bash
# Quality gate JaCoCo: LINE >= 90% e BRANCH >= 90% sobre os dados de execução já produzidos
# pelas suítes (target/jacoco-unit.exec e target/jacoco-it.exec). Não executa testes.
# Retornos: 0 = PASS, 3 = SKIP (sem código ou branches elegíveis), 1 = FAIL.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"
TARGET="${ROOT_DIR}/target"
REPORT="${TARGET}/site/jacoco/jacoco.xml"

[[ -f "${ROOT_DIR}/pom.xml" && -f "${ROOT_DIR}/mvnw" ]] || {
  echo "[FAIL] pom.xml ou Maven Wrapper não encontrado." >&2; exit 1;
}

# Mesma exclusão declarada no jacoco-maven-plugin (bootstrap sem regra de negócio).
if [[ ! -d "${ROOT_DIR}/src/main/java" ]] ||
   ! find "${ROOT_DIR}/src/main/java" -type f -name '*.java' \
     ! -name 'package-info.java' ! -name 'JavaAiEngineeringLabApplication.java' -print -quit | grep -q .; then
  echo "[SKIP] Cobertura: não existe código elegível em src/main/java."
  exit 3
fi

exec_files=()
for file in jacoco-unit.exec jacoco-it.exec; do
  [[ -s "${TARGET}/${file}" ]] && exec_files+=("${file}")
done
if (( ${#exec_files[@]} == 0 )); then
  echo "[FAIL] Cobertura: há código elegível, mas não há dados de execução JaCoCo." >&2
  echo "       Execute as suítes antes (bash scripts/verify.sh)." >&2
  exit 1
fi

# Não reaproveitar evidência anterior.
rm -f "${TARGET}/jacoco-merged.exec" "${REPORT}"

cd "${ROOT_DIR}"
echo "[INFO] Cobertura: dados ${exec_files[*]}; metas LINE >= 90% e BRANCH >= 90%."
code=0
bash ./mvnw --batch-mode --no-transfer-progress \
  jacoco:merge@coverage-merge jacoco:report@coverage-report jacoco:check@coverage-check || code=$?

[[ -f "${REPORT}" ]] || {
  echo "[FAIL] Cobertura: relatório ${REPORT} ausente; medição não comprovada." >&2; exit 1;
}

# Os contadores do nível <report> são os últimos de cada tipo no XML.
counter() {
  { grep -oE "<counter type=\"$1\" missed=\"[0-9]+\" covered=\"[0-9]+\"/>" "${REPORT}" || true; } | tail -n 1 |
    sed -E 's/.*missed="([0-9]+)" covered="([0-9]+)".*/\1 \2/'
}
read -r line_missed line_covered <<< "$(counter LINE)" || true
read -r branch_missed branch_covered <<< "$(counter BRANCH)" || true
line_total=$(( ${line_missed:-0} + ${line_covered:-0} ))
branch_total=$(( ${branch_missed:-0} + ${branch_covered:-0} ))
percent() { (( $2 == 0 )) && echo "n/a" || awk -v c="$1" -v t="$2" 'BEGIN { printf "%.2f%%", 100 * c / t }'; }
echo "[INFO] Cobertura: LINE=$(percent "${line_covered:-0}" "${line_total}") (${line_covered:-0}/${line_total}); BRANCH=$(percent "${branch_covered:-0}" "${branch_total}") (${branch_covered:-0}/${branch_total})."
echo "[INFO] Relatórios: target/site/jacoco/index.html e target/site/jacoco/jacoco.xml"

if (( code != 0 )); then
  echo "[FAIL] Cobertura: jacoco:check rejeitou os limites ou Maven falhou." >&2
  exit 1
fi
if (( line_total == 0 )); then
  echo "[SKIP] Cobertura: nenhuma linha elegível medida; meta não comprovada."
  exit 3
fi
if (( branch_total == 0 )); then
  echo "[SKIP] Cobertura: LINE aprovada, mas não há branches elegíveis; meta BRANCH não comprovada."
  exit 3
fi
echo "[PASS] Cobertura: LINE e BRANCH atendem às metas."
