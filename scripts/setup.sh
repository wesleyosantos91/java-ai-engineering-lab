#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

source "${SCRIPT_DIR}/lib/app.sh" || exit 1
require_maven_project || exit 1
command -v java >/dev/null 2>&1 || { echo "ERRO: Java não disponível no PATH." >&2; exit 1; }

cd "${APP_ROOT}"
echo "[INFO] Projeto Maven: ${APP_PREFIX:-./}pom.xml (QUALITY_GATES=${QUALITY_GATES})."
echo "[INFO] Bash: ${BASH_VERSION}"
echo "[INFO] Versão Java:"
java_version="$(java -version 2>&1)"
printf '%s\n' "${java_version}"
# Java exigido: java.version do pom do app (AGENTS.md, seção 2). Inspeção apenas: diverge -> aviso.
java_major="$(sed -n 's/.*version "\([0-9]*\).*/\1/p' <<<"${java_version}" | head -n 1)"
java_required="$(sed -n 's#.*<java.version>\([0-9]*\)</java.version>.*#\1#p' pom.xml | head -n 1)"
if [[ -z "${java_required}" ]]; then
  echo "[AVISO] java.version ausente em ${APP_PREFIX}pom.xml; versão exigida não verificada." >&2
elif [[ "${java_major}" == "${java_required}" ]]; then
  echo "[OK] Java ${java_major}, conforme ${APP_PREFIX}pom.xml."
elif [[ "${java_major}" =~ ^[0-9]+$ ]] && (( java_major > java_required )); then
  echo "[OK] Java ${java_major} no PATH compila para java.version ${java_required} (${APP_PREFIX}pom.xml)."
else
  echo "[AVISO] Java ${java_major:-desconhecido} no PATH; ${APP_PREFIX}pom.xml exige ${java_required}. Build e testes podem divergir." >&2
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
