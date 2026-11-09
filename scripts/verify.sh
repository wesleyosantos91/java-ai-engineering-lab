#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

[[ -f "${ROOT_DIR}/pom.xml" ]] || { echo "ERRO: pom.xml não encontrado." >&2; exit 1; }

build='NOT RUN'
unit='NOT RUN'
integration='NOT RUN'
summary() {
  echo "[RESUMO] Build=${build}; Unitários=${unit}; Integração=${integration}"
  echo "[NOT RUN] JaCoCo, PIT e ArchUnit não configurados."
}
trap summary EXIT

case "${SKIP_INTEGRATION:-0}" in
  0|1) ;;
  *) echo "[FAIL] SKIP_INTEGRATION deve ser 0 ou 1." >&2; exit 1 ;;
esac

# Guard de branch não é parte da verificação: experimentos podem usar HEAD destacado.
echo "[1/3] Build"
build=FAIL
bash "${SCRIPT_DIR}/build.sh"
build=PASS

echo "[2/3] Testes unitários"
if bash "${SCRIPT_DIR}/test-unit.sh"; then
  unit=PASS
else
  code=$?
  if [[ "${code}" == 3 ]]; then unit=SKIP; else unit=FAIL; exit "${code}"; fi
fi

if [[ "${SKIP_INTEGRATION:-0}" == 1 ]]; then
  integration=SKIP
  echo "[3/3] [SKIP] Integração omitida explicitamente: SKIP_INTEGRATION=1"
else
  echo "[3/3] Testes de integração"
  if bash "${SCRIPT_DIR}/test-integration.sh"; then
    integration=PASS
  else
    code=$?
    if [[ "${code}" == 3 ]]; then integration=SKIP; else integration=FAIL; exit "${code}"; fi
  fi
fi

if [[ "${unit}" == SKIP || "${integration}" == SKIP ]]; then
  echo "[PARCIAL] Há verificações omitidas; SKIP não equivale a PASS."
else
  echo "[PASS] Compilação e ambas as suítes executadas com sucesso."
fi
