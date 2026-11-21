#!/usr/bin/env bash
set -Eeuo pipefail

# Lista o que falta preencher no PRD, agrupado por responsável (Negócio, Engenharia), a partir dos
# campos [PREENCHER-NEGÓCIO: ...], [PREENCHER-ENGENHARIA: ...] e [PREENCHER...] do template
# docs/product/TEMPLATE.md. Impede que um PRD com pendências seja marcado como Aprovado.
#
# Uso: bash scripts/product/check-prd.sh [arquivo]   (padrão: docs/product/prd.md)
# Retornos: 0 = PASS, sem pendências; 3 = SKIP, PRD ausente ou em elaboração com pendências;
#           1 = FAIL, Status Aprovado com pendências ou sem critério de aceitação (### CA-NN).

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
prd="${1:-${ROOT_DIR}/docs/product/prd.md}"
(( $# <= 1 )) || { echo "Uso: bash scripts/product/check-prd.sh [arquivo]" >&2; exit 1; }

if [[ ! -f "${prd}" ]]; then
  echo "[SKIP] PRD ausente: ${prd}. Copie docs/product/TEMPLATE.md para docs/product/prd.md."
  exit 3
fi

# Uma passada: status do cabeçalho (antes da primeira seção), critérios e pendências por seção.
report="$(awk '
  { sub(/\r$/, "") }
  /^## / { section = substr($0, 4); in_header = 0 }
  FNR == 1 { in_header = 1 }
  in_header && status == "" && /^\*\*Status:\*\*/ { status = $0; sub(/^\*\*Status:\*\*[[:space:]]*/, "", status); sub(/\\$/, "", status) }
  /^### CA-[0-9]+/ { criteria++ }
  {
    # Campos citados em código (`[PREENCHER-...]`) são exemplos da orientação, não pendências.
    line = $0; gsub(/`\[PREENCHER[^`]*`/, "", line)
    while (match(line, /\[PREENCHER[^]]*\]/)) {
      field = substr(line, RSTART, RLENGTH); line = substr(line, RSTART + RLENGTH)
      owner = field ~ /^\[PREENCHER-NEG/ ? "Negócio" : field ~ /^\[PREENCHER-ENG/ ? "Engenharia" : "Sem responsável"
      where = section == "" ? "Cabeçalho" : section
      printf "item\t%s\t%d\t%s\t%s\n", owner, FNR, where, field
    }
  }
  END { printf "status\t%s\ncriteria\t%d\n", status, criteria }' "${prd}")"

status="$(sed -n 's/^status\t//p' <<<"${report}")"
criteria="$(sed -n 's/^criteria\t//p' <<<"${report}")"
items="$(grep '^item' <<<"${report}" || true)"
count="$(grep -c '^item' <<<"${report}" || true)"
rel="${prd#"${ROOT_DIR}"/}"

if [[ -n "${items}" ]]; then
  echo "[INFO] Pendências em ${rel} (status: ${status:-não informado}):"
  for owner in 'Negócio' 'Engenharia' 'Sem responsável'; do
    owner_items="$(awk -F '\t' -v o="${owner}" '$2 == o' <<<"${items}")"
    [[ -n "${owner_items}" ]] || continue
    echo "  ${owner} ($(wc -l <<<"${owner_items}" | tr -d ' ')):"
    awk -F '\t' '{ printf "    - linha %d, %s: %s\n", $3, $4, $5 }' <<<"${owner_items}"
  done
fi

shopt -s nocasematch
if [[ "${status}" =~ ^aprovad ]]; then
  if (( count > 0 )); then
    echo "[FAIL] PRD marcado como Aprovado com ${count} campo(s) pendente(s)." >&2; exit 1
  fi
  if (( criteria == 0 )); then
    echo "[FAIL] PRD marcado como Aprovado sem critério de aceitação (### CA-NN)." >&2; exit 1
  fi
fi
if (( count > 0 )); then
  echo "[SKIP] PRD em elaboração: ${count} campo(s) pendente(s)."
  exit 3
fi
echo "[PASS] PRD sem campos pendentes (${criteria} critério(s) de aceitação; status: ${status:-não informado})."
