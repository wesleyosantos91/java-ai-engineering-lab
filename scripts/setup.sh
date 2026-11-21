#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

[[ -f "${ROOT_DIR}/pom.xml" ]] || { echo "ERRO: pom.xml não encontrado." >&2; exit 1; }
[[ -f "${ROOT_DIR}/mvnw" ]] || { echo "ERRO: Maven Wrapper não encontrado." >&2; exit 1; }
command -v java >/dev/null 2>&1 || { echo "ERRO: Java não disponível no PATH." >&2; exit 1; }

cd "${ROOT_DIR}"
echo "[INFO] Bash: ${BASH_VERSION}"
echo "[INFO] Versão Java:"
java_version="$(java -version 2>&1)"
printf '%s\n' "${java_version}"
# Stack do projeto: Java 27 (AGENTS.md, seção 2). Inspeção apenas: diverge -> aviso, não falha.
java_major="$(sed -n 's/.*version "\([0-9]*\).*/\1/p' <<<"${java_version}" | head -n 1)"
if [[ "${java_major}" == 27 ]]; then
  echo "[OK] Java ${java_major}, conforme a stack."
else
  echo "[AVISO] Java ${java_major:-desconhecido} no PATH; a stack exige Java 27. Build e testes podem divergir." >&2
fi
echo "[INFO] Versão Maven resolvida pelo Wrapper:"
bash ./mvnw --version

# agents/check-config.sh usa python ou node para validar .claude/settings.json.
json_tool=''
for tool in python3 python node; do
  command -v "${tool}" >/dev/null 2>&1 && { json_tool="${tool}"; break; }
done
if [[ -n "${json_tool}" ]]; then
  echo "[OK] Validação JSON da configuração de agentes disponível (${json_tool})."
else
  echo "[AVISO] Sem python ou node; agents/check-config.sh não validará JSON." >&2
fi

# Hooks Git do projeto (commit-msg e pre-commit): opcionais, informados sem falhar.
bash "${SCRIPT_DIR}/git/install-hooks.sh" --status || true

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  echo "[OK] Docker disponível para testes de integração."
else
  echo "[AVISO] Docker indisponível; testes de integração exigirão Docker ativo." >&2
fi
