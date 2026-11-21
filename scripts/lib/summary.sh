#!/usr/bin/env bash
# Compartilhado por scripts/verify.sh e scripts/ci.sh; não deve ser executado diretamente.
# Grava o resumo legível por máquina de uma execução do harness, para CI e agentes.
# Exige lib/app.sh carregado (ROOT_DIR, APP_ROOT, APP_DIR, QUALITY_GATES, KIT_VERSION).
#
# Formato (schema 1): result (PASS, PARCIAL ou FAIL), steps (etapa -> PASS, SKIP, FAIL ou NOT RUN),
# app_dir, quality_gates, kit_version, generated_at (UTC) e reports (relatórios existentes,
# relativos à raiz).

# Resultado agregado: FAIL se alguma etapa falhou; PARCIAL se alguma foi SKIP ou NOT RUN.
summary_result() {
  local status any_partial=0
  for status in "$@"; do
    case "${status}" in
      FAIL) echo FAIL; return ;;
      PASS) ;;
      *) any_partial=1 ;;
    esac
  done
  (( any_partial )) && echo PARCIAL || echo PASS
}

# Uso: write_summary <arquivo> <resultado> etapa=status...
write_summary() {
  local file="$1" result="$2" pair first=1 report
  shift 2
  mkdir -p "$(dirname -- "${file}")"
  {
    printf '{\n  "schema": 1,\n  "result": "%s",\n  "generated_at": "%s",\n' "${result}" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '  "app_dir": "%s",\n  "quality_gates": "%s",\n  "kit_version": "%s",\n  "steps": {' \
      "${APP_DIR}" "${QUALITY_GATES}" "${KIT_VERSION:-}"
    for pair in "$@"; do
      (( first )) || printf ','
      printf '\n    "%s": "%s"' "${pair%%=*}" "${pair#*=}"
      first=0
    done
    printf '\n  },\n  "reports": ['
    first=1
    for report in surefire-reports architecture-reports failsafe-reports site/jacoco pit-reports; do
      [[ -d "${APP_ROOT}/target/${report}" ]] || continue
      (( first )) || printf ','
      printf '\n    "%starget/%s"' "${APP_PREFIX}" "${report}"
      first=0
    done
    printf '\n  ]\n}\n'
  } > "${file}"
}
