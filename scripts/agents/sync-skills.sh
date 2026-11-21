#!/usr/bin/env bash
set -Eeuo pipefail

# Gera os adaptadores .claude/skills/<nome>/SKILL.md a partir das skills canônicas em
# .agents/skills/ (ADR-0002). Os stubs copiam o frontmatter e apenas referenciam a skill
# canônica. Com --check, nada é escrito: retorna 1 se houver stub ausente, divergente ou órfão.
# Processos são caros no Git Bash: uma única passada awk e expansões do Bash no laço.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
SOURCE_DIR="${ROOT_DIR}/.agents/skills"
TARGET_DIR="${ROOT_DIR}/.claude/skills"
MARKER='<!-- Gerado por scripts/agents/sync-skills.sh a partir de'
NL=$'\n'

mode=write
case "${1:-}" in
  '') ;;
  --check) mode=check ;;
  *) echo "Uso: bash scripts/agents/sync-skills.sh [--check]" >&2; exit 1 ;;
esac

[[ -d "${SOURCE_DIR}" ]] || { echo "[FAIL] ${SOURCE_DIR} não encontrado." >&2; exit 1; }

# Monta em STUB o stub esperado de uma skill, sem subshell.
render_stub() {
  local name="$1" frontmatter="$2"
  STUB="${frontmatter}${NL}${NL}${MARKER} .agents/skills/${name}/SKILL.md. Não edite; altere a skill canônica e execute o script. -->${NL}${NL}# ${name}${NL}${NL}Adaptador para o Claude Code. Leia e siga integralmente a skill canônica${NL}[\`.agents/skills/${name}/SKILL.md\`](../../../.agents/skills/${name}/SKILL.md).${NL}${NL}Carregue arquivos de \`.agents/skills/${name}/references/\` somente quando a skill canônica indicar."
}

skill_files=()
for dir in "${SOURCE_DIR}"/*/; do
  [[ -f "${dir}SKILL.md" ]] && skill_files+=("${dir}SKILL.md")
done

problems=0
expected_names=()
if (( ${#skill_files[@]} > 0 )); then
  # Registros separados por NUL: caminho, status (ok|invalid) e frontmatter delimitado por '---'.
  while IFS= read -r -d '' source && IFS= read -r -d '' status && IFS= read -r -d '' frontmatter; do
    name="${source%/SKILL.md}"
    name="${name##*/}"
    expected_names+=("${name}")
    if [[ "${status}" != ok ]]; then
      echo "[FAIL] ${source}: frontmatter YAML ausente ou não delimitado por '---'." >&2
      problems=$((problems + 1)); continue
    fi
    render_stub "${name}" "${frontmatter}"
    stub="${TARGET_DIR}/${name}/SKILL.md"
    if [[ "${mode}" == check ]]; then
      if [[ ! -f "${stub}" ]]; then
        echo "[FAIL] Stub ausente: .claude/skills/${name}/SKILL.md" >&2; problems=$((problems + 1))
      elif [[ "$(<"${stub}")" != "${STUB}" ]]; then
        echo "[FAIL] Stub divergente: .claude/skills/${name}/SKILL.md" >&2; problems=$((problems + 1))
      fi
    else
      mkdir -p "${TARGET_DIR}/${name}"
      printf '%s\n' "${STUB}" > "${stub}"
    fi
  done < <(awk '
    function emit() {
      if (file == "") return
      printf "%s%c%s%c%s%c", file, 0, (closed ? "ok" : "invalid"), 0, block, 0
    }
    FNR == 1 { emit(); file = FILENAME; closed = 0; opened = ($0 == "---"); block = $0; next }
    opened && !closed { block = block "\n" $0; if ($0 == "---") closed = 1 }
    END { emit() }' "${skill_files[@]}")
fi

# Stubs órfãos: diretório em .claude/skills sem skill canônica correspondente.
if [[ -d "${TARGET_DIR}" ]]; then
  for dir in "${TARGET_DIR}"/*/; do
    [[ -d "${dir}" ]] || continue
    name="${dir%/}"
    name="${name##*/}"
    [[ " ${expected_names[*]} " == *" ${name} "* ]] && continue
    if [[ "${mode}" == write ]] && [[ -f "${dir}SKILL.md" ]] && grep -Fq "${MARKER}" "${dir}SKILL.md" &&
       [[ "$(find "${dir}" -type f | wc -l)" -eq 1 ]]; then
      rm -r -- "${dir}"
      echo "[INFO] Stub órfão removido: .claude/skills/${name}"
    else
      echo "[FAIL] Diretório órfão ou não gerado em .claude/skills/${name}; remova-o ou crie a skill canônica." >&2
      problems=$((problems + 1))
    fi
  done
fi

if (( problems > 0 )); then
  echo "[FAIL] Adaptadores de skills: ${problems} problema(s). Execute: bash scripts/agents/sync-skills.sh" >&2
  exit 1
fi
if [[ "${mode}" == check ]]; then
  echo "[PASS] Adaptadores de skills sincronizados: ${#expected_names[@]} skill(s)."
else
  echo "[OK] Adaptadores de skills gerados: ${#expected_names[@]} skill(s) em .claude/skills/."
fi
