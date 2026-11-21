#!/usr/bin/env bash
# Smoke k6 de disponibilidade contra uma aplicação já em execução (BASE_URL).
# Execução explícita, fora do verify.sh. Não mede desempenho: valida resposta e health UP.
# Retornos: 0 = PASS, 3 = SKIP (sem cenário k6), 1 = FAIL (k6 ausente, aplicação inacessível
# ou threshold violado).
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
BASE_URL="${BASE_URL:-http://localhost:8080}"
source "${SCRIPT_DIR}/../lib/app.sh" || exit 1
SUMMARY="${APP_PREFIX}target/performance/smoke-summary.json"

cd "${ROOT_DIR}"
# Projetos: tests/performance/k6/ (fora do app); este lab: performance/k6/.
SCENARIO=''
for candidate in tests/performance/k6/smoke.js performance/k6/smoke.js; do
  [[ -f "${candidate}" ]] && { SCENARIO="${candidate}"; break; }
done
if [[ -z "${SCENARIO}" ]]; then
  echo "[SKIP] Performance: nenhum cenário k6 (tests/performance/k6/smoke.js); smoke NOT RUN."
  exit 3
fi
command -v k6 >/dev/null 2>&1 || {
  echo "[FAIL] Performance: k6 não encontrado no PATH; instale-o (https://grafana.com/docs/k6/latest/set-up/install-k6/)." >&2
  exit 1
}
command -v curl >/dev/null 2>&1 || { echo "[FAIL] Performance: curl não encontrado no PATH." >&2; exit 1; }

if ! curl --silent --fail --max-time 5 --output /dev/null "${BASE_URL}/actuator/health"; then
  echo "[FAIL] Performance: aplicação inacessível em ${BASE_URL}/actuator/health; smoke NOT RUN." >&2
  echo "       Inicie-a em outro terminal: (cd ${APP_DIR} && bash ./mvnw spring-boot:test-run) (PostgreSQL via Testcontainers; exige Docker)." >&2
  exit 1
fi

mkdir -p "$(dirname -- "${SUMMARY}")"
rm -f "${SUMMARY}"
echo "[INFO] Performance: smoke k6 contra ${BASE_URL} (duração ${DURATION:-10s})."
code=0
BASE_URL="${BASE_URL}" k6 run --quiet --summary-export "${SUMMARY}" "${SCENARIO}" || code=$?
if (( code != 0 )); then
  echo "[FAIL] Performance: k6 terminou com exit ${code} (threshold violado ou erro). Resumo: ${SUMMARY}" >&2
  exit 1
fi
[[ -s "${SUMMARY}" ]] || { echo "[FAIL] Performance: resumo ${SUMMARY} ausente; execução não comprovada." >&2; exit 1; }
echo "[PASS] Performance: smoke de disponibilidade aprovado. Resumo: ${SUMMARY}"
