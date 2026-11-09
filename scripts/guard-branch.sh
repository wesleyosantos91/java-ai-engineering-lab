#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

git -C "${ROOT_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "ERRO: pasta não pertence a um repositório Git." >&2
  exit 1
}

branch="$(git -C "${ROOT_DIR}" symbolic-ref --quiet --short HEAD)" || {
  echo "ERRO: HEAD destacado; escolha uma branch antes de realizar operações de entrega." >&2
  exit 1
}

case "${branch}" in
  develop|main|master)
    echo "ERRO: operações de entrega não devem usar a branch protegida ${branch}." >&2
    exit 1
    ;;
esac

echo "[OK] Branch de trabalho: ${branch}"
# Este guard é local; não substitui branch protection/rulesets no GitHub.
