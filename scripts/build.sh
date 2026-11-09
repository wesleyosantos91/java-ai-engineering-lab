
#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

if [[ ! -f "${ROOT_DIR}/pom.xml" ]]; then
  echo "ERRO: pom.xml não encontrado." >&2
  exit 1
fi

if [[ ! -f "${ROOT_DIR}/mvnw" ]]; then
  echo "ERRO: Maven Wrapper não encontrado." >&2
  exit 1
fi

cd "${ROOT_DIR}"

echo "Iniciando compilação do Java AI Engineering Lab..."

./mvnw --batch-mode --no-transfer-progress clean compile

echo "Compilação concluída com sucesso."
