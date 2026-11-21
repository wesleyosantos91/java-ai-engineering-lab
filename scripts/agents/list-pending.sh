#!/usr/bin/env bash
set -Eeuo pipefail

# Lista os campos a preencher do projeto ([PREENCHER-NEGÓCIO: ...], [PREENCHER-ENGENHARIA: ...] e
# [PREENCHER...]/[ADAPTAR...] sem responsável) nos documentos Markdown, agrupados por responsável.
# Ignora templates (TEMPLATE.md), stubs gerados (.claude/), o app e trechos entre crases, que
# citam os campos como exemplo. O PRD tem verificação própria: scripts/product/check-prd.sh.
#
# Uso: bash scripts/agents/list-pending.sh
# Retornos: 0 = PASS, nada a preencher; 3 = SKIP, há campos pendentes (listados).

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
cd -- "${ROOT_DIR}"

files=()
while IFS= read -r -d '' file; do files+=("${file#./}"); done < <(find . \
  \( -path ./.git -o -path ./target -o -path ./app -o -path ./.claude -o -path ./node_modules -o -path ./.idea \) -prune -o \
  -type f -name '*.md' ! -name TEMPLATE.md -print0 | sort -z)
(( ${#files[@]} > 0 )) || { echo "[PASS] Nenhum documento Markdown encontrado."; exit 0; }

items="$(awk '
  FNR == 1 { fence = 0 }
  /^[[:space:]]*(```|~~~)/ { fence = !fence; next }
  fence { next }
  {
    # Comentários HTML (marcadores do kit) e código citado não são campos a preencher.
    line = $0; gsub(/<!--.*-->/, "", line); gsub(/`[^`]*`/, "", line)
    while (match(line, /\[(PREENCHER|ADAPTAR)[^]]*\]/)) {
      field = substr(line, RSTART, RLENGTH); line = substr(line, RSTART + RLENGTH)
      owner = field ~ /^\[PREENCHER-NEG/ ? "Negócio" : field ~ /^\[PREENCHER-ENG/ ? "Engenharia" : "Sem responsável"
      printf "%s\t%s:%d\t%s\n", owner, FILENAME, FNR, field
    }
  }' "${files[@]}")"

if [[ -z "${items}" ]]; then
  echo "[PASS] Nenhum campo a preencher nos documentos do projeto."
  exit 0
fi
total="$(wc -l <<<"${items}" | tr -d ' ')"
echo "[INFO] Campos a preencher (${total}):"
for owner in 'Negócio' 'Engenharia' 'Sem responsável'; do
  owner_items="$(awk -F '\t' -v o="${owner}" '$1 == o' <<<"${items}")"
  [[ -n "${owner_items}" ]] || continue
  echo "  ${owner} ($(wc -l <<<"${owner_items}" | tr -d ' ')):"
  awk -F '\t' '{ printf "    - %s  %s\n", $2, $3 }' <<<"${owner_items}"
done
echo "[SKIP] Projeto com ${total} campo(s) pendente(s); SKIP não equivale a PASS."
exit 3
