#!/usr/bin/env bash
set -Eeuo pipefail

# Varredura de segredos com gitleaks (regras padrão + .gitleaks.toml).
#   scan-secrets.sh            histórico Git e árvore de trabalho
#   scan-secrets.sh --staged   somente o diff preparado (hook pre-commit)
# Usa o gitleaks local ou, na falta dele, a imagem oficial fixada por digest via Docker.
# Retornos: 0 = PASS; 3 = SKIP (sem gitleaks e sem Docker); 1 = FAIL (segredo encontrado ou erro).
# Os achados são exibidos com --redact: o valor do segredo não aparece na saída.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
# ghcr.io/gitleaks/gitleaks:v8.30.1, digest verificado em 2026-11-20.
IMAGE='ghcr.io/gitleaks/gitleaks@sha256:c00b6bd0aeb3071cbcb79009cb16a60dd9e0a7c60e2be9ab65d25e6bc8abbb7f'
CONFIG='.gitleaks.toml'

mode=full
case "${1:-}" in
  '') ;;
  --staged) mode=staged ;;
  *) echo "Uso: bash scripts/security/scan-secrets.sh [--staged]" >&2; exit 1 ;;
esac

# Em git commit -a ou git commit <caminhos>, o Git usa um índice temporário (GIT_INDEX_FILE).
# A varredura precisa ler esse índice, não o padrão: torna o caminho absoluto antes do cd.
if [[ -n "${GIT_INDEX_FILE:-}" && "${GIT_INDEX_FILE}" != /* && ! "${GIT_INDEX_FILE}" =~ ^[A-Za-z]: ]]; then
  export GIT_INDEX_FILE="$(pwd -P)/${GIT_INDEX_FILE}"
fi

cd "${ROOT_DIR}"
[[ -f "${CONFIG}" ]] || { echo "[FAIL] Segredos: ${CONFIG} não encontrado." >&2; exit 1; }

# Monta o executor: gitleaks local ou contêiner com o repositório em /repo.
if command -v gitleaks >/dev/null 2>&1; then
  runner=(gitleaks)
  repo='.'
elif command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  host_dir="${ROOT_DIR}"
  # Git Bash: o Docker Desktop precisa do caminho Windows (C:/...).
  if pwd -W >/dev/null 2>&1; then host_dir="$(pwd -W)"; fi
  # O contêiner não herda o ambiente: o índice temporário é repassado com o caminho em /repo.
  env_args=()
  if [[ -n "${GIT_INDEX_FILE:-}" ]]; then
    index="${GIT_INDEX_FILE}"
    if command -v cygpath >/dev/null 2>&1; then index="$(cygpath -u "${index}")"; fi
    case "${index}" in
      "${ROOT_DIR}"/*) env_args=(-e "GIT_INDEX_FILE=/repo/${index#"${ROOT_DIR}"/}") ;;
      *) echo "[FAIL] Segredos: índice ${GIT_INDEX_FILE} fora do repositório; varredura via Docker impossível." >&2
         exit 1 ;;
    esac
  fi
  export MSYS_NO_PATHCONV=1
  runner=(docker run --rm "${env_args[@]}" -v "${host_dir}:/repo" -w /repo "${IMAGE}")
  repo='/repo'
else
  echo "[SKIP] Segredos: gitleaks e Docker indisponíveis; varredura NOT RUN."
  exit 3
fi

scan() {
  "${runner[@]}" "$@" --config "${repo}/${CONFIG}" --redact --verbose --no-banner --log-level warn
}

code=0
if [[ "${mode}" == staged ]]; then
  echo "[INFO] Segredos: varrendo o diff preparado."
  scan git --pre-commit --staged "${repo}" || code=$?
else
  echo "[INFO] Segredos: varrendo histórico Git e árvore de trabalho."
  scan git "${repo}" || code=$?
  if (( code == 0 )); then scan dir "${repo}" || code=$?; fi
fi

case "${code}" in
  0) echo "[PASS] Segredos: nenhum segredo encontrado." ;;
  1) echo "[FAIL] Segredos: possíveis segredos encontrados (valores ocultos). Remova-os e revogue as credenciais expostas." >&2; exit 1 ;;
  *) echo "[FAIL] Segredos: gitleaks falhou (exit ${code}); varredura não comprovada." >&2; exit 1 ;;
esac
