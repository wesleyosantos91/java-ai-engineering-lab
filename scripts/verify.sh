#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

source "${SCRIPT_DIR}/lib/app.sh" || exit 1
require_maven_project || exit 1

agents='NOT RUN'
build='NOT RUN'
unit='NOT RUN'
architecture='NOT RUN'
integration='NOT RUN'
coverage='NOT RUN'
source "${SCRIPT_DIR}/lib/summary.sh"
# Resumo legível por máquina (CI e agentes); docs/how-to/ci-integration.md.
VERIFY_SUMMARY="${APP_ROOT}/target/harness/verify-summary.json"
summary() {
  echo "[RESUMO] Agentes=${agents}; Build=${build}; Unitários=${unit}; Arquitetura=${architecture}; Integração=${integration}; Cobertura=${coverage}; Mutação=NOT RUN"
  echo "[NOT RUN] Mutação (PIT) exige execução explícita: bash scripts/quality/mutation.sh."
  write_summary "${VERIFY_SUMMARY}" \
    "$(summary_result "${agents}" "${build}" "${unit}" "${architecture}" "${integration}" "${coverage}")" \
    "agents=${agents}" "build=${build}" "unit=${unit}" "architecture=${architecture}" \
    "integration=${integration}" "coverage=${coverage}" 2>/dev/null &&
    echo "[INFO] Resumo: ${APP_PREFIX}target/harness/verify-summary.json" ||
    echo "[AVISO] Resumo JSON não gravado em ${VERIFY_SUMMARY}." >&2
}
trap summary EXIT
source "${SCRIPT_DIR}/lib/lock.sh"
acquire_harness_lock || exit 1

case "${SKIP_INTEGRATION:-0}" in
  0|1) ;;
  *) echo "[FAIL] SKIP_INTEGRATION deve ser 0 ou 1." >&2; exit 1 ;;
esac

# Executa uma etapa e registra PASS (0), SKIP (3) ou FAIL (demais códigos, que interrompem o fluxo).
run_step() {
  local status_var="$1" script="$2" code=0
  bash "${SCRIPT_DIR}/${script}" || code=$?
  case "${code}" in
    0) printf -v "${status_var}" PASS ;;
    3) printf -v "${status_var}" SKIP ;;
    *) printf -v "${status_var}" FAIL; exit "${code}" ;;
  esac
}

# Guard de branch não é parte da verificação: revisões e spikes podem usar HEAD destacado.
echo "[1/6] Configuração de agentes"
agents=FAIL
bash "${SCRIPT_DIR}/agents/check-config.sh"
agents=PASS

echo "[2/6] Build"
build=FAIL
bash "${SCRIPT_DIR}/build/compile.sh"
build=PASS

echo "[3/6] Testes unitários"
run_step unit test/unit.sh

echo "[4/6] Arquitetura (ArchUnit)"
run_step architecture test/architecture.sh

if [[ "${SKIP_INTEGRATION:-0}" == 1 ]]; then
  integration=SKIP
  echo "[5/6] [SKIP] Integração omitida explicitamente: SKIP_INTEGRATION=1"
  coverage=SKIP
  echo "[6/6] [SKIP] Cobertura não medida: dados de integração ausentes."
else
  echo "[5/6] Testes de integração"
  run_step integration test/integration.sh
  echo "[6/6] Cobertura (JaCoCo)"
  run_step coverage quality/coverage.sh
fi

if [[ "${unit}" == SKIP || "${architecture}" == SKIP || "${integration}" == SKIP || "${coverage}" == SKIP ]]; then
  echo "[PARCIAL] Há verificações omitidas; SKIP não equivale a PASS."
else
  echo "[PASS] Fluxo padrão aprovado: configuração de agentes, build, unitários, arquitetura, integração e cobertura."
  echo "[PARCIAL] Quality gates completos exigem também a mutação (NOT RUN neste fluxo)."
fi
