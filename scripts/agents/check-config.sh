#!/usr/bin/env bash
set -Eeuo pipefail

# Verifica a configuração de contexto dos agentes (ADR-0002) sem Maven nem Docker.
# Retornos: 0 = PASS; 1 = FAIL. AGENT_CONTEXT_MAX_BYTES ajusta o limite do AGENTS.md
# somente para testes do harness; alterar o padrão exige revisão do ADR-0002.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
MAX_BYTES="${AGENT_CONTEXT_MAX_BYTES:-12288}"
failures=0

fail() { echo "[FAIL] $*" >&2; failures=$((failures + 1)); }
pass() { echo "[PASS] $*"; }

cd -- "${ROOT_DIR}"

# 1. AGENTS.md existe e respeita o orçamento de contexto fixo.
if [[ ! -f AGENTS.md ]]; then
  fail "AGENTS.md não encontrado."
else
  size="$(wc -c < AGENTS.md | tr -d '[:space:]')"
  if (( size > MAX_BYTES )); then
    fail "AGENTS.md tem ${size} bytes; limite ${MAX_BYTES}. Mova detalhes para docs/how-to ou skills."
  else
    pass "AGENTS.md: ${size} de ${MAX_BYTES} bytes."
  fi
fi

# 2. Frontmatter das skills canônicas: name igual ao diretório e description presente.
# Uma única passada awk sobre todas as skills: no Git Bash, cada processo custa caro.
skills=()
skill_files=()
for dir in .agents/skills/*/; do
  [[ -d "${dir}" ]] || continue
  if [[ -f "${dir}SKILL.md" ]]; then
    skills+=("$(basename -- "${dir}")")
    skill_files+=("${dir}SKILL.md")
  else
    fail "${dir} sem SKILL.md."
  fi
done
if (( ${#skill_files[@]} > 0 )); then
  # Saída por arquivo: caminho<TAB>name<TAB>description(1|0).
  while IFS=$'\t' read -r file declared has_description; do
    name="$(basename -- "$(dirname -- "${file}")")"
    [[ "${declared}" == "${name}" ]] || fail "${file}: name '${declared}' difere do diretório '${name}'."
    [[ "${has_description}" == 1 ]] || fail "${file}: description ausente ou vazia."
  done < <(awk '
    function emit() { if (file != "") printf "%s\t%s\t%d\n", file, name, desc }
    FNR == 1 { emit(); file = FILENAME; name = ""; desc = 0; state = ($0 == "---") ? 1 : 2; folded = 0; next }
    state != 1 { next }
    { sub(/\r$/, "") }
    $0 == "---" { state = 2; next }
    folded && /^[[:space:]]+[^[:space:]]/ { desc = 1; folded = 0; next }
    { folded = 0 }
    /^name:/ { value = $0; sub(/^name:[[:space:]]*/, "", value); if (name == "") name = value; next }
    /^description:/ { value = $0; sub(/^description:[[:space:]]*/, "", value)
      if (value ~ /^[>|][-+]?$/ || value == "") folded = 1; else desc = 1 }
    END { emit() }' "${skill_files[@]}")
fi
(( ${#skills[@]} > 0 )) || fail "Nenhuma skill canônica em .agents/skills/."
pass "Skills canônicas inspecionadas: ${#skills[@]}."

# 3. Catálogo de skills do AGENTS.md igual aos diretórios existentes.
if [[ -f AGENTS.md ]]; then
  catalog="$(sed -n 's/^|[^|]*|[[:space:]]*`\([a-z0-9-]*\)`[[:space:]]*|.*/\1/p' AGENTS.md | sort -u)"
  existing="$(printf '%s\n' "${skills[@]}" | sort -u)"
  missing="$(comm -13 <(printf '%s\n' "${catalog}") <(printf '%s\n' "${existing}") | sed '/^$/d')"
  unknown="$(comm -23 <(printf '%s\n' "${catalog}") <(printf '%s\n' "${existing}") | sed '/^$/d')"
  [[ -z "${missing}" ]] || fail "Skills ausentes do catálogo do AGENTS.md: $(tr '\n' ' ' <<<"${missing}")"
  [[ -z "${unknown}" ]] || fail "Catálogo do AGENTS.md cita skills inexistentes: $(tr '\n' ' ' <<<"${unknown}")"
  [[ -n "${missing}${unknown}" ]] || pass "Catálogo de skills do AGENTS.md coerente com .agents/skills/."
fi

# 4. Adaptadores do Claude Code: import do AGENTS.md e stubs sincronizados.
if [[ -f CLAUDE.md ]] && grep -Eq '^@AGENTS\.md[[:space:]]*$' CLAUDE.md; then
  pass "CLAUDE.md importa @AGENTS.md."
else
  fail "CLAUDE.md ausente ou sem a linha '@AGENTS.md'."
fi
if sync_output="$(bash "${SCRIPT_DIR}/sync-skills.sh" --check 2>&1)"; then
  pass "Stubs .claude/skills sincronizados."
else
  printf '%s\n' "${sync_output}" >&2
  fail "Stubs .claude/skills divergentes."
fi

# 5. Configurações de provider: JSON válido e hooks referenciados existentes.
if [[ -f .claude/settings.json ]]; then
  json_ok=unknown
  for interpreter in python3 python node; do
    command -v "${interpreter}" >/dev/null 2>&1 || continue
    if [[ "${interpreter}" == node ]]; then
      node -e 'JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"))' .claude/settings.json 2>/dev/null && json_ok=yes || json_ok=no
    else
      "${interpreter}" -c 'import json, sys; json.load(open(sys.argv[1], encoding="utf-8"))' .claude/settings.json 2>/dev/null && json_ok=yes || json_ok=no
    fi
    break
  done
  case "${json_ok}" in
    yes) pass ".claude/settings.json é JSON válido." ;;
    no) fail ".claude/settings.json não é JSON válido." ;;
    *) echo "[WARN] Sem python/node; validade JSON de .claude/settings.json NÃO VERIFICADA." ;;
  esac
  # .github/ pertence ao time de DevOps (AGENTS.md, seção 8): edição por agentes negada.
  for rule in 'Edit(./.github/**)' 'Write(./.github/**)'; do
    grep -qF "\"${rule}\"" .claude/settings.json || fail ".claude/settings.json sem deny ${rule} (.github/ é gerido por DevOps)."
  done
  while IFS= read -r hook; do
    [[ -f "${hook}" ]] || fail ".claude/settings.json referencia hook inexistente: ${hook}"
  done < <(grep -o 'CLAUDE_PROJECT_DIR/[^"\\]*' .claude/settings.json | sed 's#^CLAUDE_PROJECT_DIR/##')
fi

# 6. Links relativos Markdown resolvíveis (fora de blocos de código).
# Uma passada awk extrai os links de todos os .md versionáveis; a existência é testada no Bash.
link_failures=0
docs=()
while IFS= read -r -d '' doc; do docs+=("${doc}"); done < <(find . \
  \( -path ./target -o -path ./.git -o -path ./.idea -o -path ./node_modules \) -prune -o \
  -type f -name '*.md' -print0)
if (( ${#docs[@]} > 0 )); then
  while IFS=$'\t' read -r doc line target; do
    target="${target%%#*}"
    target="${target%% *}"
    [[ -n "${target}" ]] || continue
    if [[ ! -e "${doc%/*}/${target}" ]]; then
      fail "Link quebrado em ${doc#./}:${line} -> ${target}"
      link_failures=$((link_failures + 1))
    fi
  done < <(awk 'FNR == 1 { fence = 0 }
    /^[[:space:]]*(```|~~~)/ { fence = !fence; next }
    !fence {
      line = $0; gsub(/`[^`]*`/, "", line)
      while (match(line, /\]\([^)]+\)/)) {
        target = substr(line, RSTART + 2, RLENGTH - 3)
        if (target !~ /^(https?:|mailto:|#)/) printf "%s\t%d\t%s\n", FILENAME, FNR, target
        line = substr(line, RSTART + RLENGTH)
      }
    }' "${docs[@]}")
fi
(( link_failures > 0 )) || pass "Links relativos Markdown resolvíveis em ${#docs[@]} arquivo(s)."

# 6b. Marcadores do kit de adoção (scripts/agents/export-kit.sh): só os tipos conhecidos e
# blocos omit-start/omit-end balanceados, sem aninhamento.
marker_failures=0
if (( ${#docs[@]} > 0 )); then
  while IFS= read -r problem; do
    fail "Marcador do kit inválido: ${problem}"
    marker_failures=$((marker_failures + 1))
  done < <(awk '
    FNR == 1 { if (prev != "" && open) printf "%s: omit-start sem omit-end\n", prev; open = 0 }
    { prev = FILENAME; line = $0
      while (match(line, /<!-- kit:[a-z-]+/)) {
        kind = substr(line, RSTART + 9, RLENGTH - 9)
        if (kind == "omit-start") { if (open) printf "%s:%d: omit-start aninhado\n", FILENAME, FNR; open = 1 }
        else if (kind == "omit-end") { if (!open) printf "%s:%d: omit-end sem omit-start\n", FILENAME, FNR; open = 0 }
        else if (kind != "omit-line" && kind != "replace-line") printf "%s:%d: tipo desconhecido kit:%s\n", FILENAME, FNR, kind
        line = substr(line, RSTART + RLENGTH)
      } }
    END { if (open) printf "%s: omit-start sem omit-end\n", prev }' "${docs[@]}")
fi
(( marker_failures > 0 )) || pass "Marcadores do kit válidos."

# 6b'. .harness: chaves válidas; em projetos, o pom fica sempre em app/ (docs/architecture/
# repository-layout.md). Só este repositório de referência (identificado pelo ADR-0004) usa a raiz.
if harness_error="$(source "${ROOT_DIR}/scripts/lib/app.sh" 2>&1 >/dev/null)"; then
  harness_dir="$(source "${ROOT_DIR}/scripts/lib/app.sh" && printf '%s' "${APP_DIR}")"
  if compgen -G 'docs/architecture/adr/0004-*.md' >/dev/null || [[ "${harness_dir}" == app ]]; then
    pass ".harness válido (APP_DIR=${harness_dir})."
  else
    fail ".harness: APP_DIR=${harness_dir}; em projetos o pom fica em app/ (APP_DIR=app)."
  fi
else
  fail "${harness_error#\[FAIL\] }"
fi

# 6c. PRD: pendências são esperadas em elaboração; aprovação com pendências é rejeitada.
prd_code=0
prd_output="$(bash "${ROOT_DIR}/scripts/product/check-prd.sh" 2>&1)" || prd_code=$?
case "${prd_code}" in
  0) pass "PRD sem campos pendentes." ;;
  3) echo "[INFO] PRD em elaboração ou ausente; detalhes: bash scripts/product/check-prd.sh." ;;
  *) printf '%s\n' "${prd_output}" >&2; fail "PRD inválido (scripts/product/check-prd.sh)." ;;
esac

# 7. Caminhos scripts/*.sh citados em documentação e configuração existem. O registro de
# aprendizados é histórico imutável e preserva os caminhos da época; fica fora.
path_failures=0
refs=()
while IFS= read -r -d '' file; do refs+=("${file}"); done < <(find . \
  \( -path ./target -o -path ./.git -o -path ./.idea -o -path ./node_modules \) -prune -o \
  -type f \( -name '*.md' -o -name '*.sh' -o -name '*.json' -o -name '*.toml' -o -name '*.rules' \) \
  ! -path ./docs/ai/lessons-learned.md -print0)
if (( ${#refs[@]} > 0 )); then
  while IFS=$'\t' read -r file line path; do
    if [[ ! -f "${path}" ]]; then
      fail "Caminho inexistente em ${file#./}:${line} -> ${path}"
      path_failures=$((path_failures + 1))
    fi
  done < <(awk '{
      line = $0
      while (match(line, /(^|[^[:alnum:]_\/.$-])scripts\/[[:alnum:]_.\/-]+\.sh/)) {
        hit = substr(line, RSTART, RLENGTH); sub(/^[^s]*/, "", hit)
        printf "%s\t%d\t%s\n", FILENAME, FNR, hit
        line = substr(line, RSTART + RLENGTH)
      }
    }' "${refs[@]}" | sort -u -t $'\t' -k3,3 -k1,1)
fi
(( path_failures > 0 )) || pass "Caminhos scripts/*.sh citados existem."

# 8. Nenhum arquivo do harness ou da configuração de agentes pode estar ignorado pelo Git:
# um padrão genérico (por exemplo, build/) faria o arquivo sumir no commit sem aviso.
# Só se aplica quando ROOT_DIR é a raiz do repositório (não a uma cópia de teste dentro de target/).
if [[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" == true && -z "$(git rev-parse --show-prefix 2>/dev/null)" ]]; then
  # Arquivos pessoais que o projeto manda ignorar (.gitignore, "Agentes de IA (arquivos locais)")
  # não são artefatos compartilhados perdidos; somente eles ficam fora desta verificação.
  local_files=(.claude/settings.local.json)
  ignored="$({ find scripts performance .agents .claude .codex .github .devcontainer -type f 2>/dev/null
    printf '%s\n' AGENTS.md CLAUDE.md SECURITY.md .gitleaks.toml .editorconfig .harness; } |
    { grep -vxF -f <(printf '%s\n' "${local_files[@]}") || true; } |
    git check-ignore --stdin 2>/dev/null || true)"
  if [[ -n "${ignored}" ]]; then
    while IFS= read -r file; do fail "Arquivo ignorado pelo .gitignore e não versionável: ${file}"; done <<<"${ignored}"
  else
    pass "Arquivos do harness e dos agentes não estão ignorados pelo Git."
  fi
else
  echo "[WARN] Raiz fora de um repositório Git próprio; verificação de .gitignore NÃO EXECUTADA."
fi

if (( failures > 0 )); then
  echo "[FAIL] Configuração de agentes: ${failures} problema(s)." >&2
  exit 1
fi
echo "[PASS] Configuração de agentes verificada."
