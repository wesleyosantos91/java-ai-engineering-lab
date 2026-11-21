#!/usr/bin/env bash
set -Eeuo pipefail

# Instala (ou remove, com --uninstall) os hooks versionados em scripts/git/hooks/ via
# core.hooksPath. A configuração é local ao clone e não afeta outros repositórios.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
HOOKS_PATH='scripts/git/hooks'

git -C "${ROOT_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "[FAIL] Pasta não pertence a um repositório Git." >&2; exit 1;
}

case "${1:-}" in
  '')
    current="$(git -C "${ROOT_DIR}" config --local --get core.hooksPath || true)"
    if [[ -n "${current}" && "${current}" != "${HOOKS_PATH}" ]]; then
      echo "[FAIL] core.hooksPath já aponta para '${current}'; remova-o antes de instalar." >&2
      exit 1
    fi
    git -C "${ROOT_DIR}" config --local core.hooksPath "${HOOKS_PATH}"
    echo "[OK] Hooks instalados: core.hooksPath=${HOOKS_PATH} (commit-msg, pre-commit)."
    ;;
  --uninstall)
    if [[ "$(git -C "${ROOT_DIR}" config --local --get core.hooksPath || true)" == "${HOOKS_PATH}" ]]; then
      git -C "${ROOT_DIR}" config --local --unset core.hooksPath
      echo "[OK] Hooks removidos (core.hooksPath desfeito)."
    else
      echo "[OK] Hooks do projeto não estavam instalados."
    fi
    ;;
  --status)
    if [[ "$(git -C "${ROOT_DIR}" config --local --get core.hooksPath || true)" == "${HOOKS_PATH}" ]]; then
      echo "[OK] Hooks do projeto instalados (${HOOKS_PATH})."
    else
      echo "[AVISO] Hooks do projeto não instalados; execute bash scripts/git/install-hooks.sh."
      exit 3
    fi
    ;;
  *) echo "Uso: bash scripts/git/install-hooks.sh [--uninstall|--status]" >&2; exit 1 ;;
esac
