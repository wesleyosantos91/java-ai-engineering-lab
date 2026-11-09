#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

[[ -f "${ROOT_DIR}/mvnw" ]] || { echo "ERRO: Maven Wrapper não encontrado." >&2; exit 1; }

# Convenção provisória: classes *Test.java = unitários; *IT.java = integração.
# A classe inicial JavaAiEngineeringLabApplicationTests é tratada como integração.
if [[ ! -d "${ROOT_DIR}/src/test/java" ]] || \
   ! find "${ROOT_DIR}/src/test/java" -type f -name '*Test.java' -print -quit | grep -q .; then
  echo "[SKIP] Não existem testes unitários *Test.java no projeto."
  exit 0
fi

cd "${ROOT_DIR}"
echo "[INFO] Executando testes unitários (*Test)..."
bash ./mvnw --batch-mode --no-transfer-progress '-Dtest=*Test' test
echo "[OK] Testes unitários executados com sucesso."
