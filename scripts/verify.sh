#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

[[ -f "${ROOT_DIR}/pom.xml" ]] || { echo "ERRO: pom.xml não encontrado." >&2; exit 1; }

# Guard de branch não é parte da verificação: experimentos podem usar HEAD destacado.
echo "[1/3] Build"
bash "${SCRIPT_DIR}/build.sh"

echo "[2/3] Testes unitários"
bash "${SCRIPT_DIR}/test-unit.sh"

if [[ "${SKIP_INTEGRATION:-0}" == "1" ]]; then
  echo "[3/3] [SKIP] Integração omitida explicitamente: SKIP_INTEGRATION=1"
  echo "[PARCIAL] Compilação e testes unitários disponíveis verificados."
  exit 0
fi

echo "[3/3] Testes de integração"
bash "${SCRIPT_DIR}/test-integration.sh"

echo "[OK] Verificações disponíveis concluídas."
echo "[AVISO] JaCoCo, PIT e ArchUnit ainda não estão configurados."
