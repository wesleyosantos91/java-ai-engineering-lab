#!/usr/bin/env bash
set -Eeuo pipefail

# Prova, em cópias temporárias, que agents/check-config.sh e agents/sync-skills.sh rejeitam
# violações e aprovam a configuração conforme, e que o hook do Claude bloqueia entrega em develop.
# Não usa Maven nem Docker; não altera a árvore de trabalho real.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
mkdir -p "${ROOT_DIR}/target"
WORK="$(mktemp -d "${ROOT_DIR}/target/agent-config-check.XXXXXX")"

# Cria uma cópia mínima e conforme da configuração de agentes em "$1".
make_fixture() {
  local dest="$1"
  mkdir -p "${dest}"
  local items=() item
  # Somente o que existe: num repositório gerado pelo kit, LICENSE e NOTICE podem faltar.
  for item in AGENTS.md CLAUDE.md README.md CONTRIBUTING.md LICENSE NOTICE SECURITY.md .gitleaks.toml .harness \
    .devcontainer .agents .claude .github docs performance scripts; do
    [[ -e "${ROOT_DIR}/${item}" ]] && items+=("${item}")
  done
  (cd "${ROOT_DIR}" && tar -cf - "${items[@]}") | (cd "${dest}" && tar -xf -)
  # O .harness exige que APP_DIR exista; o conteúdo do app não importa para este check.
  mkdir -p "${dest}/$(source "${ROOT_DIR}/scripts/lib/app.sh" && printf '%s' "${APP_DIR}")"
}

check() {
  local expected="$1" message="$2" fixture="$3" script="$4" code=0
  shift 4
  # Argumentos restantes vão ao script; variáveis de ambiente opcionais vêm de CHECK_ENV.
  # shellcheck disable=SC2086
  (cd "${fixture}" && env ${CHECK_ENV:-} bash "scripts/${script}" "$@") > "${WORK}/output" 2>&1 || code=$?
  if [[ "${code}" != "${expected}" ]] || ! grep -Fq -- "${message}" "${WORK}/output"; then
    cat "${WORK}/output"
    echo "[FAIL] ${script}: esperado exit=${expected}, observado=${code}, texto=${message}" >&2
    exit 1
  fi
  echo "[PASS] ${script}: exit=${code}; ${message}"
}

n=0
# Define f com uma cópia nova e conforme (sem subshell, para preservar o contador).
fresh() { n=$((n + 1)); f="${WORK}/case ${n}"; make_fixture "${f}"; }

# Conforme.
fresh
check 0 '[PASS] Configuração de agentes verificada.' "${f}" agents/check-config.sh
check 0 '[PASS] Adaptadores de skills sincronizados' "${f}" agents/sync-skills.sh --check

# Stub divergente: description alterada à mão.
fresh
sed -i 's/^description:.*/description: editado manualmente/' "${f}/.claude/skills/tdd-workflow/SKILL.md"
check 1 'Stub divergente: .claude/skills/tdd-workflow/SKILL.md' "${f}" agents/sync-skills.sh --check
check 1 'Stubs .claude/skills divergentes' "${f}" agents/check-config.sh
check 0 'Adaptadores de skills gerados' "${f}" agents/sync-skills.sh
check 0 '[PASS] Configuração de agentes verificada.' "${f}" agents/check-config.sh

# Stub ausente e stub órfão.
fresh
rm -r "${f}/.claude/skills/code-review"
check 1 'Stub ausente: .claude/skills/code-review/SKILL.md' "${f}" agents/sync-skills.sh --check
fresh
cp -R "${f}/.claude/skills/code-review" "${f}/.claude/skills/removed-skill"
check 1 'Diretório órfão' "${f}" agents/sync-skills.sh --check
check 0 'Stub órfão removido: .claude/skills/removed-skill' "${f}" agents/sync-skills.sh
mkdir -p "${f}/.claude/skills/manual-skill" && echo manual > "${f}/.claude/skills/manual-skill/SKILL.md"
check 1 'Diretório órfão ou não gerado em .claude/skills/manual-skill' "${f}" agents/sync-skills.sh
[[ -f "${f}/.claude/skills/manual-skill/SKILL.md" ]] || { echo '[FAIL] sync removeu diretório não gerado.' >&2; exit 1; }

# Skill canônica sem frontmatter e com name divergente.
fresh
mkdir -p "${f}/.agents/skills/broken-skill" && echo '# sem frontmatter' > "${f}/.agents/skills/broken-skill/SKILL.md"
check 1 'frontmatter YAML ausente' "${f}" agents/sync-skills.sh --check
fresh
sed -i 's/^name: tdd-workflow$/name: tdd/' "${f}/.agents/skills/tdd-workflow/SKILL.md"
check 1 "name 'tdd' difere do diretório 'tdd-workflow'" "${f}" agents/check-config.sh

# Skill fora do catálogo do AGENTS.md (com stub sincronizado, para isolar a regra).
fresh
cp -R "${f}/.agents/skills/code-review" "${f}/.agents/skills/new-skill"
sed -i 's/^name: code-review$/name: new-skill/' "${f}/.agents/skills/new-skill/SKILL.md"
(cd "${f}" && bash scripts/agents/sync-skills.sh >/dev/null)
check 1 'Skills ausentes do catálogo do AGENTS.md: new-skill' "${f}" agents/check-config.sh

# CLAUDE.md sem import do AGENTS.md.
fresh
sed -i '/^@AGENTS\.md/d' "${f}/CLAUDE.md"
check 1 "CLAUDE.md ausente ou sem a linha '@AGENTS.md'" "${f}" agents/check-config.sh

# Link relativo quebrado; links em blocos de código e externos são ignorados.
fresh
printf '\n[quebrado](docs/inexistente.md)\n' >> "${f}/README.md"
check 1 'Link quebrado em README.md' "${f}" agents/check-config.sh
fresh
printf '\n```text\n[exemplo](nao/existe.md)\n```\n[externo](https://example.com/x)\n' >> "${f}/README.md"
check 0 '[PASS] Links relativos Markdown resolvíveis' "${f}" agents/check-config.sh

# Caminho de script citado que não existe (regressão de renomeação); o registro histórico é ignorado.
# Montado em tempo de execução para que este arquivo não cite o caminho inexistente.
missing_script="scripts/""old-name.sh"
fresh
printf '\nExecute `bash %s`.\n' "${missing_script}" >> "${f}/CONTRIBUTING.md"
check 1 'Caminho inexistente em CONTRIBUTING.md' "${f}" agents/check-config.sh
fresh
printf '\n- Evidência histórica: `%s`.\n' "${missing_script}" >> "${f}/docs/ai/lessons-learned.md"
check 0 '[PASS] Caminhos scripts/*.sh citados existem.' "${f}" agents/check-config.sh

# Orçamento de contexto do AGENTS.md e JSON inválido.
fresh
CHECK_ENV=AGENT_CONTEXT_MAX_BYTES=100 check 1 'limite 100' "${f}" agents/check-config.sh
fresh
echo '{ invalido' > "${f}/.claude/settings.json"
check 1 '.claude/settings.json não é JSON válido.' "${f}" agents/check-config.sh

# .github/ é gerido por DevOps: remover o deny do Claude Code é detectado.
fresh
sed -i '/"Edit(.\/.github\/\*\*)",/d' "${f}/.claude/settings.json"
check 1 'sem deny Edit(./.github/**)' "${f}" agents/check-config.sh

# .harness: chave inválida rejeitada; fora deste repositório de referência (sem ADR-0004), o
# projeto Maven precisa estar em app/.
fresh
printf 'APP_DIR=.\nEXTRA=1\n' > "${f}/.harness"
check 1 "chave desconhecida 'EXTRA'" "${f}" agents/check-config.sh
fresh
# Projeto (REPOSITORY_ROLE=project, padrão): o pom fica em app/. Só o repositório de referência
# declara outro APP_DIR, e o papel inválido é rejeitado.
printf 'APP_DIR=.\n' > "${f}/.harness"
check 1 'em projetos o pom fica em app/' "${f}" agents/check-config.sh
printf 'APP_DIR=.\nREPOSITORY_ROLE=reference\n' > "${f}/.harness"
check 0 '[PASS] .harness válido (APP_DIR=.)' "${f}" agents/check-config.sh
printf 'APP_DIR=.\nREPOSITORY_ROLE=legado\n' > "${f}/.harness"
check 1 "REPOSITORY_ROLE 'legado' inválido" "${f}" agents/check-config.sh
mkdir -p "${f}/app"
printf 'APP_DIR=app\n' > "${f}/.harness"
check 0 '[PASS] .harness válido (APP_DIR=app)' "${f}" agents/check-config.sh

# PRD: template em elaboração é aceito (pendências listadas por responsável); aprovado com
# pendências é rejeitado, e só os campos fora de código contam.
fresh
cp "${f}/docs/product/TEMPLATE.md" "${f}/docs/product/prd.md"
check 0 'PRD em elaboração ou ausente' "${f}" agents/check-config.sh
check 3 'Engenharia (' "${f}" product/check-prd.sh
grep -Fq 'Negócio (' "${WORK}/output"
sed -i 's/^\*\*Status:\*\* Rascunho/**Status:** Aprovado/' "${f}/docs/product/prd.md"
check 1 'PRD inválido' "${f}" agents/check-config.sh
check 1 'Aprovado com' "${f}" product/check-prd.sh
sed -i 's/\[PREENCHER[^]]*\]/ok/g' "${f}/docs/product/prd.md"
check 0 '[PASS] PRD sem campos pendentes (1 critério' "${f}" product/check-prd.sh
sed -i '/^### CA-/d' "${f}/docs/product/prd.md"
check 1 'sem critério de aceitação' "${f}" product/check-prd.sh

# Arquivos ignorados: a cópia vira um repositório Git próprio (sem commits) para que a
# verificação 8 execute. Preferências locais declaradas são permitidas; um script novo
# ignorado por padrão genérico (build/) é detectado.
fresh
cp "${ROOT_DIR}/.gitignore" "${f}/.gitignore"
git -C "${f}" init -q
echo '{}' > "${f}/.claude/settings.local.json"
check 0 '[PASS] Arquivos do harness e dos agentes não estão ignorados pelo Git.' "${f}" agents/check-config.sh
sed -i '/^!\/scripts\/build\/$/d' "${f}/.gitignore"
check 1 'não versionável: scripts/build/compile.sh' "${f}" agents/check-config.sh

# Hook PreToolUse do Claude: bloqueia commit/push em develop e permite em feature/*.
repo="${WORK}/hook repo"
mkdir -p "${repo}/scripts/git" "${repo}/scripts/agents/hooks"
cp "${ROOT_DIR}/scripts/git/guard-branch.sh" "${repo}/scripts/git/"
cp "${ROOT_DIR}/scripts/agents/hooks/claude-pre-bash.sh" "${repo}/scripts/agents/hooks/"
git -C "${repo}" init -q -b develop
hook() {
  local expected="$1" command="$2" code=0
  printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "${command}" |
    bash "${repo}/scripts/agents/hooks/claude-pre-bash.sh" > "${WORK}/output" 2>&1 || code=$?
  if [[ "${code}" != "${expected}" ]]; then
    cat "${WORK}/output"
    echo "[FAIL] hook: '${command}' esperado exit=${expected}, observado=${code}" >&2
    exit 1
  fi
  echo "[PASS] hook: '${command}' exit=${code}"
}
hook 2 'git commit -m x'
hook 2 'git push origin develop'
hook 2 'cd app && git -C . push'
hook 0 'git status'
hook 0 'git log --grep commit'
hook 0 'bash scripts/verify.sh'
git -C "${repo}" checkout -q -b feature/example
hook 0 'git commit -m x'
hook 0 'git push origin feature/example'

echo "[PASS] Configuração de agentes e hook verificados em cópias temporárias. Fixtures: ${WORK}"
