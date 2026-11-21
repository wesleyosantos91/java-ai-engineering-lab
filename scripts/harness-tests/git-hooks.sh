#!/usr/bin/env bash
set -Eeuo pipefail

# Prova, em repositório Git temporário, que check-commit-msg.sh aplica as regras do
# AGENTS.md, seção 9, e que os hooks instalados por install-hooks.sh bloqueiam commits
# inválidos. Não altera o repositório real nem sua configuração Git.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
mkdir -p "${ROOT_DIR}/target"
WORK="$(mktemp -d "${ROOT_DIR}/target/git-hooks-check.XXXXXX")"
# Objetos Git são somente leitura no Windows e impediriam o "mvn clean" de apagar target/:
# o repositório temporário é removido ao sair, inclusive em falha.
cleanup() { chmod -R u+w "${WORK}" 2>/dev/null || true; rm -rf "${WORK}"; }
trap cleanup EXIT
CHECK="${ROOT_DIR}/scripts/git/check-commit-msg.sh"

expect() {
  local expected="$1" message="$2" code=0
  shift 2
  "$@" > "${WORK}/output" 2>&1 || code=$?
  if [[ "${code}" != "${expected}" ]] || { [[ -n "${message}" ]] && ! grep -Fq -- "${message}" "${WORK}/output"; }; then
    cat "${WORK}/output"
    echo "[FAIL] esperado exit=${expected} e '${message}'; observado exit=${code}: $*" >&2
    exit 1
  fi
  echo "[PASS] exit=${code}; ${message}"
}

msg() { printf '%b' "$1" > "${WORK}/msg"; echo "${WORK}/msg"; }

# Mensagens: formato, tipo, ponto final, tamanho, coautoria, comentários e mensagens do Git.
expect 0 '' bash "${CHECK}" "$(msg 'feat(product): add product creation endpoint\n')"
expect 0 '' bash "${CHECK}" "$(msg 'docs: describe harness\n\nBody line.\n')"
expect 0 '' bash "${CHECK}" "$(msg 'feat(api)!: change product response contract\n\nBREAKING CHANGE: explained.\n')"
expect 0 '' bash "${CHECK}" "$(msg '# comentário do editor\nfix: prevent duplicate sku\n# Please enter the commit message\n')"
expect 0 '' bash "${CHECK}" "$(msg "Merge branch 'feature/x' into develop\n")"
expect 0 '' bash "${CHECK}" "$(msg 'fixup! feat: add endpoint\n')"
expect 1 'fora de Conventional Commits' bash "${CHECK}" "$(msg 'Feat: add endpoint\n')"
expect 1 'fora de Conventional Commits' bash "${CHECK}" "$(msg 'feature: add endpoint\n')"
expect 1 'fora de Conventional Commits' bash "${CHECK}" "$(msg 'feat:add endpoint\n')"
expect 1 'fora de Conventional Commits' bash "${CHECK}" "$(msg 'add endpoint\n')"
expect 1 'não deve terminar com ponto final' bash "${CHECK}" "$(msg 'feat: add endpoint.\n')"
expect 1 'máximo 100' bash "${CHECK}" "$(msg "feat: $(printf 'a%.0s' {1..100})\n")"
expect 1 'mensagem vazia' bash "${CHECK}" "$(msg '# só comentário\n\n')"
expect 1 'coautoria proibida' bash "${CHECK}" "$(msg 'feat: add endpoint\n\nCo-Authored-By: Someone <someone@example.invalid>\n')"
expect 1 'coautoria proibida' bash "${CHECK}" "$(msg 'feat: add endpoint\n\nco-authored-by: Agent <agent@example.invalid>\n')"
expect 1 'coautoria proibida' bash "${CHECK}" "$(msg "Merge branch 'x'\n\nCo-Authored-By: A <a@example.invalid>\n")"

# Repositório temporário com os scripts reais de git/ e dependências do pre-commit simuladas.
repo="${WORK}/repo with spaces"
mkdir -p "${repo}/scripts/agents" "${repo}/scripts/security"
cp -R "${ROOT_DIR}/scripts/git" "${repo}/scripts/git"
printf '#!/usr/bin/env bash\nexit 0\n' > "${repo}/scripts/agents/check-config.sh"
printf '#!/usr/bin/env bash\necho "[SKIP] Segredos simulados."\nexit 3\n' > "${repo}/scripts/security/scan-secrets.sh"
git -C "${repo}" init -q -b develop
git -C "${repo}" config user.name 'Harness Test'
git -C "${repo}" config user.email 'harness@example.invalid'
commit() { git -C "${repo}" commit -q --allow-empty -m "$1" "${@:2}"; }

# --range sem hooks instalados: um commit inválido no histórico reprova o range.
commit 'chore: initial commit'
commit 'docs: add guide'
expect 0 '2 mensagem(ns) válida(s)' bash -c "cd '${repo}' && bash scripts/git/check-commit-msg.sh --range HEAD"
commit 'Added stuff.'
expect 1 '1 de 1 mensagem(ns) inválida(s)' bash -c "cd '${repo}' && bash scripts/git/check-commit-msg.sh --range HEAD~1..HEAD"
expect 0 'nenhum commit no range' bash -c "cd '${repo}' && bash scripts/git/check-commit-msg.sh --range HEAD..HEAD"
expect 1 'Range inválido' bash -c "cd '${repo}' && bash scripts/git/check-commit-msg.sh --range nao-existe..HEAD"

# Instalação: status, hooks ativos, bloqueio de mensagem e de branch protegida, desinstalação.
expect 3 'não instalados' bash "${repo}/scripts/git/install-hooks.sh" --status
expect 0 'Hooks instalados' bash "${repo}/scripts/git/install-hooks.sh"
expect 0 'instalados (scripts/git/hooks)' bash "${repo}/scripts/git/install-hooks.sh" --status
expect 1 'branch protegida develop' commit 'feat: blocked on develop'
git -C "${repo}" checkout -q -b feature/example
expect 1 'coautoria proibida' commit $'feat: add endpoint\n\nCo-Authored-By: Agent <agent@example.invalid>'
expect 1 'fora de Conventional Commits' commit 'wip'
expect 0 '[SKIP] Segredos simulados.' commit 'feat(product): add product creation endpoint'
printf 'trailing   \n' > "${repo}/file.txt"
git -C "${repo}" add file.txt
expect 1 'espaços em branco inválidos' commit 'docs: add file'
git -C "${repo}" reset -q
expect 0 'Hooks removidos' bash "${repo}/scripts/git/install-hooks.sh" --uninstall
expect 0 '' commit 'wip without hooks'
git -C "${repo}" config core.hooksPath other/hooks
expect 1 "já aponta para 'other/hooks'" bash "${repo}/scripts/git/install-hooks.sh"

echo "[PASS] Validação de commits e hooks verificada em repositório temporário (removido ao final)."
