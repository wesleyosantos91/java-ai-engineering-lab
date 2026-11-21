#!/usr/bin/env bash
set -Eeuo pipefail

# Valida mensagens de commit conforme o AGENTS.md, seção 9:
#   - cabeçalho Conventional Commits com os tipos permitidos, até 100 caracteres, sem ponto final;
#   - nenhuma atribuição de coautoria (Co-Authored-By e similares).
# Uso:
#   check-commit-msg.sh <arquivo>          modo hook (commit-msg)
#   check-commit-msg.sh --range <revs>     commits existentes, por exemplo develop..HEAD
# Retornos: 0 = PASS; 1 = FAIL. Não é possível verificar por script se a descrição está em
# inglês e no imperativo; isso continua sob revisão humana.

TYPES='feat|fix|docs|test|refactor|perf|build|ci|chore|style|revert'
HEADER_RE="^(${TYPES})(\([a-z0-9._-]+\))?!?: [^[:space:]].*$"
# Mensagens geradas pelo próprio Git ou por fluxos de autosquash.
GIT_GENERATED_RE='^(Merge |Revert "|fixup! |squash! |amend! )'
COAUTHOR_RE='^[[:space:]]*(co-authored-by|co-author|coauthored-by)[[:space:]]*:'
MAX_HEADER=100

# Valida uma mensagem (conteúdo em $1, rótulo para erros em $2). Retorna 0 ou 1.
validate() {
  local message="$1" label="$2" header='' line problems=0
  while IFS= read -r line || [[ -n "${line}" ]]; do
    line="${line%$'\r'}"
    [[ "${line}" == \#* ]] && continue
    # Corte do editor do Git (commit --verbose): o restante é o diff.
    [[ "${line}" == '# ------------------------ >8 ------------------------' ]] && break
    if [[ -z "${header}" ]]; then
      [[ -n "${line//[[:space:]]/}" ]] && header="${line}"
      continue
    fi
    shopt -s nocasematch
    if [[ "${line}" =~ ${COAUTHOR_RE} ]]; then
      echo "[FAIL] ${label}: atribuição de coautoria proibida (AGENTS.md, seção 9): ${line}" >&2
      problems=$((problems + 1))
    fi
    shopt -u nocasematch
  done <<<"${message}"

  if [[ -z "${header}" ]]; then
    echo "[FAIL] ${label}: mensagem vazia." >&2
    return 1
  fi
  if [[ "${header}" =~ ${GIT_GENERATED_RE} ]]; then
    (( problems == 0 )) && return 0 || return 1
  fi
  if [[ ! "${header}" =~ ${HEADER_RE} ]]; then
    echo "[FAIL] ${label}: cabeçalho fora de Conventional Commits: '${header}'." >&2
    echo "       Formato: <type>(<scope>): <description>; tipos: ${TYPES//|/, }." >&2
    problems=$((problems + 1))
  fi
  if (( ${#header} > MAX_HEADER )); then
    echo "[FAIL] ${label}: cabeçalho com ${#header} caracteres; máximo ${MAX_HEADER}." >&2
    problems=$((problems + 1))
  fi
  if [[ "${header}" == *. ]]; then
    echo "[FAIL] ${label}: a descrição não deve terminar com ponto final." >&2
    problems=$((problems + 1))
  fi
  (( problems == 0 ))
}

case "${1:-}" in
  --range)
    [[ -n "${2:-}" ]] || { echo "Uso: check-commit-msg.sh --range <revs>" >&2; exit 1; }
    commits="$(git rev-list --reverse "$2")" || { echo "[FAIL] Range inválido: $2" >&2; exit 1; }
    if [[ -z "${commits}" ]]; then
      echo "[PASS] Commits: nenhum commit no range $2."
      exit 0
    fi
    failures=0 total=0
    while IFS= read -r sha; do
      total=$((total + 1))
      validate "$(git log -1 --format=%B "${sha}")" "commit ${sha:0:12}" || failures=$((failures + 1))
    done <<<"${commits}"
    if (( failures > 0 )); then
      echo "[FAIL] Commits: ${failures} de ${total} mensagem(ns) inválida(s) em $2." >&2
      exit 1
    fi
    echo "[PASS] Commits: ${total} mensagem(ns) válida(s) em $2."
    ;;
  ''|-h|--help)
    echo "Uso: check-commit-msg.sh <arquivo> | --range <revs>" >&2
    exit 1
    ;;
  *)
    [[ -f "$1" ]] || { echo "[FAIL] Arquivo de mensagem não encontrado: $1" >&2; exit 1; }
    validate "$(<"$1")" "mensagem de commit" || exit 1
    ;;
esac
