#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

[[ -f "${ROOT_DIR}/pom.xml" ]] || { echo "ERRO: pom.xml não encontrado." >&2; exit 1; }
[[ -f "${ROOT_DIR}/mvnw" ]] || { echo "ERRO: Maven Wrapper não encontrado." >&2; exit 1; }
command -v java >/dev/null 2>&1 || { echo "ERRO: Java não disponível no PATH." >&2; exit 1; }

cd "${ROOT_DIR}"
echo "[INFO] Versão Java:"
java -version
echo "[INFO] Versão Maven resolvida pelo Wrapper:"
bash ./mvnw --version

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  echo "[OK] Docker disponível para testes de integração."
else
  echo "[AVISO] Docker indisponível; testes de integração exigirão Docker ativo." >&2
fi
