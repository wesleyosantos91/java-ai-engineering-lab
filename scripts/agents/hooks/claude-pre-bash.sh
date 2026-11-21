#!/usr/bin/env bash
set -Eeuo pipefail

# Hook PreToolUse (Bash) do Claude Code. Lê o JSON do evento pela entrada padrão e, para
# comandos git de entrega (commit e push), delega a scripts/git/guard-branch.sh.
# Retornos: 0 permite; 2 bloqueia, com o motivo em stderr, conforme o contrato de hooks do Claude Code.
# Os limites canônicos estão no AGENTS.md; este hook apenas os reforça localmente.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../../.." && pwd -P)"

payload="$(cat)"

# Sem jq como dependência: basta detectar git commit/push em qualquer ponto do comando,
# inclusive após opções globais como -C <dir> ou -c chave=valor.
git_delivery='(^|[^[:alnum:]_.-])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+(commit|push)([^[:alnum:]_-]|$)'
if ! grep -Eq "${git_delivery}" <<<"${payload}"; then
  exit 0
fi

if ! guard_output="$(bash "${ROOT_DIR}/scripts/git/guard-branch.sh" 2>&1)"; then
  echo "Bloqueado pelo hook do projeto: ${guard_output}" >&2
  echo "Crie uma branch feature/*, fix/* ou experiment/* (AGENTS.md, seção 9)." >&2
  exit 2
fi
exit 0
