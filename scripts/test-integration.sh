
#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

cd "${ROOT_DIR}"

if ! docker info >/dev/null 2>&1; then
  echo "ERRO: Docker não está disponível." >&2
  exit 1
fi

if [[ ! -f "./mvnw" ]]; then
  echo "ERRO: Maven Wrapper não encontrado." >&2
  exit 1
fi

echo "Executando teste de integração com Testcontainers..."

bash ./mvnw \
  --batch-mode \
  --no-transfer-progress \
  -Dtest=JavaAiEngineeringLabApplicationTests \
  test

echo "Teste de integração concluído com sucesso."
