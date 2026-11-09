#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

[[ -f "${ROOT_DIR}/pom.xml" ]] || { echo "ERRO: pom.xml não encontrado." >&2; exit 1; }
[[ -f "${ROOT_DIR}/mvnw" ]] || { echo "ERRO: Maven Wrapper não encontrado." >&2; exit 1; }

cd "${ROOT_DIR}"
echo "[INFO] Compilando Java AI Engineering Lab..."
bash ./mvnw --batch-mode --no-transfer-progress clean compile
echo "[OK] Compilação concluída."
