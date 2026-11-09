#!/usr/bin/env bash
# Compartilhado pelas duas suítes; não deve ser executado diretamente.
# Retornos: 0 = PASS, 3 = SKIP (ausência ou testes ignorados), 1 = FAIL.
run_test_suite() {
  local suite="$1" pattern="$2" reports="$3"
  shift 3
  local report_dir="${ROOT_DIR}/target/${reports}" counts total failures errors skipped

  [[ -f "${ROOT_DIR}/pom.xml" && -f "${ROOT_DIR}/mvnw" ]] || {
    echo "[FAIL] pom.xml ou Maven Wrapper não encontrado." >&2; return 1;
  }

  # Somente relatórios gerados desta suíte; não reaproveitar evidência anterior.
  if [[ -d "${report_dir}" ]]; then
    find "${report_dir}" -maxdepth 1 -type f \( -name 'TEST-*.xml' -o -name 'failsafe-summary.xml' \) -delete
  fi

  # TEST_SUITE_EXCLUDE (opcional): padrão de nome removido da elegibilidade, como os testes ArchUnit
  # excluídos da execução default do Surefire.
  if [[ ! -d "${ROOT_DIR}/src/test/java" ]] ||
     ! find "${ROOT_DIR}/src/test/java" -type f -name "${pattern}" \
       ! -name "${TEST_SUITE_EXCLUDE:-}" -print -quit | grep -q .; then
    echo "[SKIP] ${suite}: não existem classes ${pattern}."
    return 3
  fi

  if [[ "${suite}" == "Integração" ]]; then
    command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1 || {
      echo "[FAIL] Docker indisponível; integração NOT RUN." >&2; return 1;
    }
  fi

  cd "${ROOT_DIR}"
  echo "[INFO] ${suite}: executando ${pattern}..."
  if ! bash ./mvnw --batch-mode --no-transfer-progress "$@"; then
    echo "[FAIL] ${suite}: Maven falhou. Relatórios: ${report_dir}" >&2
    return 1
  fi

  # XML produzido por Surefire/Failsafe: atributos da raiz testsuite em uma linha.
  # Não contar suites aninhadas nem logs; validar os quatro contadores obrigatórios.
  counts="$(awk -F '\"' '
    FNR == 1 { if (NR > 1 && !rootSeen) invalid=1; rootSeen=0 }
    /^[[:space:]]*<testsuite / && !rootSeen {
      rootSeen=1
      n++; fields=0
      for (i=1; i<NF; i+=2) {
        if ($i ~ / (tests|failures|errors|skipped)=$/) {
          if ($(i+1) !~ /^[0-9]+$/) invalid=1
          fields++
          if ($i ~ / tests=$/) t+=$(i+1)
          if ($i ~ / failures=$/) f+=$(i+1)
          if ($i ~ / errors=$/) e+=$(i+1)
          if ($i ~ / skipped=$/) s+=$(i+1)
        }
      }
      if (fields != 4) invalid=1
    }
    END { if (!n || !rootSeen || invalid) exit 1; print t+0, f+0, e+0, s+0 }
  ' "${report_dir}"/TEST-*.xml)" || {
    echo "[FAIL] ${suite}: relatórios ausentes ou inválidos; execução não comprovada." >&2
    return 1
  }
  read -r total failures errors skipped <<< "${counts}"
  echo "[INFO] ${suite}: total=${total}, failures=${failures}, errors=${errors}, skipped=${skipped}"
  if (( total == 0 || failures > 0 || errors > 0 || skipped > total )); then
    echo "[FAIL] ${suite}: nenhum teste executado ou falhas nos relatórios." >&2
    return 1
  fi
  if (( skipped > 0 )); then
    echo "[SKIP] ${suite}: execução incompleta; consulte ${report_dir}."
    return 3
  fi
  echo "[PASS] ${suite}: $((total - skipped)) teste(s)."
}
