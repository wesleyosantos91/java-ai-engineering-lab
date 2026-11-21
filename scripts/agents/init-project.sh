#!/usr/bin/env bash
set -Eeuo pipefail

# Inicializa um repositório criado a partir do seed público (scripts/agents/export-kit.sh --seed):
# troca pacote base, classe principal, identidade Maven e nome do projeto, substitui o
# README do seed e verifica a configuração dos agentes. Não faz commit.
#
# Uso: bash scripts/agents/init-project.sh --base-package <pacote> --main-class <Classe>
#                                          --project-name <nome>
# Retornos: 0 = projeto inicializado e check-config aprovado; 1 = erro.
# Só executa num seed ainda não inicializado (pacote com.example.seed) e com working tree limpa,
# para que o resultado possa ser revisado e desfeito pelo Git.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
source "${SCRIPT_DIR}/../lib/app.sh" || exit 1
source "${SCRIPT_DIR}/../lib/pom.sh"
source "${SCRIPT_DIR}/../lib/rename.sh"

# Mesmos nomes de scripts/agents/export-kit.sh (modo --seed).
SEED_PACKAGE=com.example.seed
SEED_MAIN=SeedApplication
SEED_NAME='Java AI-First Seed'
SEED_SLUG=java-ai-first-seed

usage() {
  echo "Uso: bash scripts/agents/init-project.sh --base-package <pacote> --main-class <Classe> --project-name <nome>" >&2
  exit 1
}

new_package='' new_main='' project_name=''
while (( $# )); do
  case "$1" in
    --base-package) [[ -n "${2:-}" ]] || usage; new_package="$2"; shift 2 ;;
    --main-class) [[ -n "${2:-}" ]] || usage; new_main="$2"; shift 2 ;;
    --project-name) [[ -n "${2:-}" ]] || usage; project_name="$2"; shift 2 ;;
    *) usage ;;
  esac
done
[[ -n "${new_package}" && -n "${new_main}" && -n "${project_name}" ]] || usage
[[ "${new_package}" =~ ^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$ ]] ||
  { echo "[FAIL] --base-package inválido: '${new_package}' (ex.: com.acme.orders)." >&2; exit 1; }
[[ "${new_main}" =~ ^[A-Z][A-Za-z0-9_]*$ ]] ||
  { echo "[FAIL] --main-class inválido: '${new_main}' (ex.: OrdersApplication)." >&2; exit 1; }
slug="$(project_slug "${project_name}")"
[[ -n "${slug}" ]] || { echo "[FAIL] --project-name precisa conter letras ou números." >&2; exit 1; }

cd -- "${ROOT_DIR}"
old_package="$(pom_property app.basePackage)" || exit 1
old_main="$(pom_property app.mainClass)" || exit 1
if [[ "${old_package}" != "${SEED_PACKAGE}" || "${old_main}" != "${SEED_MAIN}" ]]; then
  echo "[FAIL] Projeto já inicializado (pacote ${old_package}, classe ${old_main}); o init só roda sobre o seed." >&2
  exit 1
fi
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[FAIL] Execute dentro do repositório Git criado a partir do template." >&2; exit 1
fi
if [[ -n "$(git status --porcelain)" ]]; then
  echo "[FAIL] Working tree com alterações; faça commit ou descarte antes de inicializar." >&2; exit 1
fi

rename_package "${ROOT_DIR}" "${SEED_PACKAGE}" "${new_package}" "${APP_DIR}"
rename_main_class "${ROOT_DIR}" "${SEED_MAIN}" "${new_main}" "${APP_DIR}"
rename_literal "${ROOT_DIR}" "${SEED_SLUG}" "${slug}"
rename_literal "${ROOT_DIR}" "${SEED_NAME}" "${project_name}"
# groupId do projeto: o pacote base sem o último segmento (com.acme.orders -> com.acme).
sed -i "/<\/parent>/,/<artifactId>/ s#<groupId>[^<]*</groupId>#<groupId>${new_package%.*}</groupId>#" "${APP_ROOT}/pom.xml"

printf '# %s\n\n[PREENCHER: o que o projeto faz e como começar.]\n\nRequisitos: [PRD](docs/product/prd.md). Instruções para agentes de IA: [AGENTS.md](AGENTS.md). Como contribuir: [CONTRIBUTING.md](CONTRIBUTING.md).\n' \
  "${project_name}" > README.md

if ! bash scripts/agents/check-config.sh >/dev/null 2>&1; then
  bash scripts/agents/check-config.sh >&2 || true
  echo "[FAIL] check-config reprovado após a inicialização; revise com git diff (git checkout -- . desfaz)." >&2
  exit 1
fi

echo "[PASS] ${project_name} inicializado: pacote ${new_package}, classe ${new_main}, artifactId ${slug}."
echo "[INFO] Próximos passos (revise com git diff antes do primeiro commit numa branch de trabalho):"
echo "  - Negócio: preencher docs/product/prd.md; pendências por responsável: bash scripts/product/check-prd.sh"
echo "  - Engenharia: AGENTS.md §1 e §2, ADRs herdados, LICENSE/NOTICE. .github/ é configurado pelo time de DevOps."
echo "  - Harness: bash scripts/git/install-hooks.sh; bash scripts/setup.sh; bash scripts/verify.sh"
