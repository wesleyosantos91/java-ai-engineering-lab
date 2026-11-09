#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

[[ -f "${ROOT_DIR}/mvnw" ]] || { echo "ERRO: Maven Wrapper não encontrado." >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "ERRO: comando docker não encontrado." >&2; exit 1; }
docker info >/dev/null 2>&1 || { echo "ERRO: Docker não está disponível." >&2; exit 1; }

cd "${ROOT_DIR}"
echo "[INFO] Executando integração com Testcontainers..."
# Compatível com o teste de contexto existente e com novos testes *IT.
bash ./mvnw --batch-mode --no-transfer-progress '-Dtest=JavaAiEngineeringLabApplicationTests,*IT' test
echo "[OK] Testes de integração executados com sucesso."
