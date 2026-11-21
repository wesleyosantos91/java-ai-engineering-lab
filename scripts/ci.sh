#!/usr/bin/env bash
set -Eeuo pipefail

# Ponto de entrada do harness para a CI (o workflow em .github/ é do time de DevOps e só chama
# este script). Sem interação; o resultado vai para a saída e para um JSON estável.
#
# Uso: bash scripts/ci.sh
# Etapas: verify.sh (agentes, build, unitários, arquitetura, integração, cobertura), mutação (PIT)
# e varredura de segredos da árvore inteira.
# Variáveis:
#   CI_MUTATION=0          omite a mutação (registrada como NOT RUN; o resultado fica PARCIAL)
#   CI_SECRETS=0           omite a varredura de segredos (NOT RUN)
#   CI_REQUIRE_COMPLETE=1  PARCIAL (alguma etapa SKIP ou NOT RUN) também falha a CI
#   SKIP_INTEGRATION=1     repassado ao verify.sh (só com justificativa; resultado PARCIAL)
# Resumo: <APP_DIR>/target/harness/ci-summary.json (formato em docs/how-to/ci-integration.md).
# Retornos: 0 = PASS, ou PARCIAL sem CI_REQUIRE_COMPLETE; 1 = FAIL.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"
source "${SCRIPT_DIR}/lib/app.sh" || exit 1
source "${SCRIPT_DIR}/lib/summary.sh"
source "${SCRIPT_DIR}/lib/lock.sh"
acquire_harness_lock || exit 1

for var in CI_MUTATION CI_SECRETS CI_REQUIRE_COMPLETE; do
  case "${!var:-}" in ''|0|1) ;; *) echo "[FAIL] ${var} deve ser 0 ou 1." >&2; exit 1 ;; esac
done
LOG_DIR="${APP_ROOT}/target/harness"

# Executa uma etapa e devolve PASS (0), SKIP (3) ou FAIL (demais códigos).
status_of() { case "$1" in 0) echo PASS ;; 3) echo SKIP ;; *) echo FAIL ;; esac; }
# Status de uma etapa no [RESUMO] do verify.sh (Agentes=PASS; Build=...).
resumo_status() { sed -n "s/^\[RESUMO\].*$1=\([A-Z ]*[A-Z]\);.*/\1/p" "${verify_log}" | tail -n 1; }

echo "[CI] 1/3 verify.sh"
verify_log="$(mktemp)"
trap 'rm -f "${verify_log}"; release_harness_lock' EXIT
set +e
bash "${SCRIPT_DIR}/verify.sh" 2>&1 | tee "${verify_log}"
code="${PIPESTATUS[0]}"
set -e
agents="$(resumo_status Agentes)" build="$(resumo_status Build)" unit="$(resumo_status Unitários)"
architecture="$(resumo_status Arquitetura)" integration="$(resumo_status Integração)" coverage="$(resumo_status Cobertura)"
if [[ -z "${agents}" ]]; then
  agents=FAIL build="NOT RUN" unit="NOT RUN" architecture="NOT RUN" integration="NOT RUN" coverage="NOT RUN"
fi

mutation='NOT RUN'
if [[ "${code}" == 0 && "${CI_MUTATION:-1}" == 1 ]]; then
  echo "[CI] 2/3 Mutação (PIT)"
  code=0; bash "${SCRIPT_DIR}/quality/mutation.sh" || code=$?
  mutation="$(status_of "${code}")"
else
  echo "[CI] 2/3 Mutação: NOT RUN ($([[ "${CI_MUTATION:-1}" == 0 ]] && echo 'CI_MUTATION=0' || echo 'verify.sh falhou'))."
fi

secrets='NOT RUN'
if [[ "${CI_SECRETS:-1}" == 1 ]]; then
  echo "[CI] 3/3 Segredos"
  code=0; bash "${SCRIPT_DIR}/security/scan-secrets.sh" || code=$?
  secrets="$(status_of "${code}")"
else
  echo "[CI] 3/3 Segredos: NOT RUN (CI_SECRETS=0)."
fi

result="$(summary_result "${agents}" "${build}" "${unit}" "${architecture}" "${integration}" "${coverage}" "${mutation}" "${secrets}")"
write_summary "${LOG_DIR}/ci-summary.json" "${result}" \
  "agents=${agents}" "build=${build}" "unit=${unit}" "architecture=${architecture}" \
  "integration=${integration}" "coverage=${coverage}" "mutation=${mutation}" "secrets=${secrets}"
echo "[CI] Agentes=${agents}; Build=${build}; Unitários=${unit}; Arquitetura=${architecture}; Integração=${integration}; Cobertura=${coverage}; Mutação=${mutation}; Segredos=${secrets}"
echo "[CI] Resumo: ${APP_PREFIX}target/harness/ci-summary.json"
case "${result}" in
  PASS) echo "[PASS] CI: todas as etapas aprovadas." ;;
  PARCIAL)
    if [[ "${CI_REQUIRE_COMPLETE:-0}" == 1 ]]; then
      echo "[FAIL] CI: resultado PARCIAL com CI_REQUIRE_COMPLETE=1 (há etapas SKIP ou NOT RUN)." >&2; exit 1
    fi
    echo "[PARCIAL] CI: há etapas SKIP ou NOT RUN; SKIP não equivale a PASS." ;;
  *) echo "[FAIL] CI: há etapas reprovadas." >&2; exit 1 ;;
esac
