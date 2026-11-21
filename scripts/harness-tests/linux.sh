#!/usr/bin/env bash
set -Eeuo pipefail

# Executa num contêiner Linux Debian (Bash, coreutils, sed e find GNU, mawk, sem Python) os testes
# de scripts/harness-tests/ que não usam Maven nem Docker: todos, exceto quality-gates.sh,
# maven-isolation.sh e este. Valida a portabilidade para runners de CI e para o
# .devcontainer. A cópia é feita dentro do contêiner, a partir dos arquivos versionáveis; nada é
# gravado na árvore de trabalho.
#
# Uso: bash scripts/harness-tests/linux.sh
#   HARNESS_LINUX_IMAGE  imagem (padrão: buildpack-deps:bookworm-scm, com Git e Bash)
# Retornos: 0 = PASS; 3 = SKIP (Docker indisponível); 1 = FAIL.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
IMAGE="${HARNESS_LINUX_IMAGE:-buildpack-deps:bookworm-scm}"

if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
  echo "[SKIP] Linux: Docker indisponível; portabilidade NÃO VERIFICADA."
  exit 3
fi
# No Git Bash, o caminho do volume precisa estar no formato do Windows e sem conversão automática.
source_dir="${ROOT_DIR}"
command -v cygpath >/dev/null 2>&1 && source_dir="$(cygpath -w "${ROOT_DIR}")"

echo "[INFO] Linux: executando os testes do harness em ${IMAGE}..."
code=0
MSYS_NO_PATHCONV=1 docker run --rm -v "${source_dir}:/src:ro" "${IMAGE}" bash -c '
  set -Eeuo pipefail
  git config --global --add safe.directory "*"
  mkdir -p /work
  (cd /src && git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf -) | tar -xf - -C /work
  cd /work
  git init -q -b feature/linux-check
  git add -A
  git -c user.name=harness -c user.email=harness@example.invalid commit -qm "chore: linux check" --no-verify
  echo "[INFO] $(bash --version | head -n 1); $(sed --version | head -n 1); awk: $(readlink -f "$(command -v awk)")"
  for path in scripts/harness-tests/*.sh; do
    test="$(basename "${path}")"
    case "${test}" in quality-gates.sh|maven-isolation.sh|linux.sh) continue ;; esac
    if bash "${path}" > "/tmp/${test}.log" 2>&1; then
      echo "[PASS] Linux: ${test}"
    else
      tail -n 30 "/tmp/${test}.log"
      echo "[FAIL] Linux: ${test}" >&2
      exit 1
    fi
  done
' || code=$?
if (( code != 0 )); then
  echo "[FAIL] Linux: testes do harness reprovados no contêiner (exit ${code})." >&2
  exit 1
fi
echo "[PASS] Linux: testes do harness aprovados em ${IMAGE}."
