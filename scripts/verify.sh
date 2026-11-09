#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

[[ -f "${ROOT_DIR}/pom.xml" ]] || { echo "ERRO: pom.xml não encontrado." >&2; exit 1; }

build='NOT RUN'
unit='NOT RUN'
architecture='NOT RUN'
integration='NOT RUN'
coverage='NOT RUN'
summary() {
  echo "[RESUMO] Build=${build}; Unitários=${unit}; Integração=${integration}; Arquitetura=${architecture}; Cobertura=${coverage}; Mutação=NOT RUN"
  echo "[NOT RUN] Mutação (PIT) exige execução explícita: bash scripts/test-mutation.sh."
}
trap summary EXIT

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

# Guard de branch não é parte da verificação: experimentos podem usar HEAD destacado.
echo "[1/5] Build"
build=FAIL
bash "${SCRIPT_DIR}/build.sh"
build=PASS

echo "[2/5] Testes unitários"
run_step unit test-unit.sh

echo "[3/5] Arquitetura (ArchUnit)"
run_step architecture test-architecture.sh

if [[ "${SKIP_INTEGRATION:-0}" == 1 ]]; then
  integration=SKIP
  echo "[4/5] [SKIP] Integração omitida explicitamente: SKIP_INTEGRATION=1"
  coverage=SKIP
  echo "[5/5] [SKIP] Cobertura não medida: dados de integração ausentes."
else
  echo "[4/5] Testes de integração"
  run_step integration test-integration.sh
  echo "[5/5] Cobertura (JaCoCo)"
  run_step coverage test-coverage.sh
fi

if [[ "${unit}" == SKIP || "${architecture}" == SKIP || "${integration}" == SKIP || "${coverage}" == SKIP ]]; then
  echo "[PARCIAL] Há verificações omitidas; SKIP não equivale a PASS."
else
  echo "[PASS] Fluxo padrão aprovado: build, unitários, arquitetura, integração e cobertura."
  echo "[PARCIAL] Quality gates completos exigem também a mutação (NOT RUN neste fluxo)."
fi
