#!/usr/bin/env bash
# Compartilhado pelos scripts do harness; não deve ser executado diretamente.
# Lê o arquivo .harness da raiz (chave=valor, sem execução de código) e define:
#   APP_DIR        diretório do projeto Maven relativo à raiz (projetos: "app"; este lab: ".")
#   APP_ROOT       caminho absoluto de APP_DIR
#   QUALITY_GATES  required (gate não configurado no pom = FAIL) | optional (= SKIP)
#   REPOSITORY_ROLE  project (padrão: pom sempre em app/) | reference (repositório de referência)
#   KIT_VERSION    versão do kit AI-First aplicada (informativa; gravada pelo instalador)
# Sem .harness: APP_DIR=., QUALITY_GATES=required, REPOSITORY_ROLE=project. Exige ROOT_DIR definido.
APP_DIR=.
QUALITY_GATES=required
REPOSITORY_ROLE=project
KIT_VERSION=
if [[ -f "${ROOT_DIR}/.harness" ]]; then
  while IFS='=' read -r key value || [[ -n "${key}" ]]; do
    key="${key//[[:space:]]/}"
    case "${key}" in
      ''|'#'*) continue ;;
      APP_DIR|QUALITY_GATES|REPOSITORY_ROLE|KIT_VERSION) ;;
      *) echo "[FAIL] .harness: chave desconhecida '${key}' (válidas: APP_DIR, QUALITY_GATES, REPOSITORY_ROLE, KIT_VERSION)." >&2; return 1 ;;
    esac
    # Comentário ao fim da linha e espaços nas bordas são descartados; espaço interno é inválido.
    value="${value%%#*}"
    value="$(sed -E 's/^[[:space:]]+|[[:space:]]+$//g' <<<"${value}")"
    [[ "${value}" != *[[:space:]]* ]] ||
      { echo "[FAIL] .harness: valor de ${key} com espaço ('${value}')." >&2; return 1; }
    printf -v "${key}" '%s' "${value}"
  done < <(tr -d '\r' < "${ROOT_DIR}/.harness")
fi
case "${APP_DIR}" in
  /*|*..*|'') echo "[FAIL] .harness: APP_DIR '${APP_DIR}' inválido; use um caminho relativo à raiz, sem '..'." >&2; return 1 ;;
esac
case "${QUALITY_GATES}" in
  required|optional) ;;
  *) echo "[FAIL] .harness: QUALITY_GATES '${QUALITY_GATES}' inválido (required ou optional)." >&2; return 1 ;;
esac
case "${REPOSITORY_ROLE}" in
  project|reference) ;;
  *) echo "[FAIL] .harness: REPOSITORY_ROLE '${REPOSITORY_ROLE}' inválido (project ou reference)." >&2; return 1 ;;
esac
APP_ROOT="$(cd -- "${ROOT_DIR}/${APP_DIR}" 2>/dev/null && pwd -P)" ||
  { echo "[FAIL] .harness: APP_DIR '${APP_DIR}' não existe." >&2; return 1; }
# Caminho do app para mensagens ("pom.xml" no lab, "app/pom.xml" em projetos).
APP_PREFIX=''
[[ "${APP_DIR}" == . ]] || APP_PREFIX="${APP_DIR%/}/"

# Exige o pom e o Maven Wrapper do app; retorna 1 com mensagem.
require_maven_project() {
  [[ -f "${APP_ROOT}/pom.xml" && -f "${APP_ROOT}/mvnw" ]] || {
    echo "[FAIL] ${APP_PREFIX}pom.xml ou Maven Wrapper (${APP_PREFIX}mvnw) não encontrado." >&2; return 1;
  }
}

# Gate sem configuração no pom: FAIL se obrigatório, SKIP (exit 3) se opcional.
# Uso: gate_not_configured <nome> <o que falta>
gate_not_configured() {
  if [[ "${QUALITY_GATES}" == optional ]]; then
    echo "[SKIP] $1: $2 não configurado em ${APP_PREFIX}pom.xml (QUALITY_GATES=optional); veja docs/how-to/enable-quality-gates.md."
    exit 3
  fi
  echo "[FAIL] $1: $2 ausente em ${APP_PREFIX}pom.xml (QUALITY_GATES=required)." >&2
  exit 1
}
