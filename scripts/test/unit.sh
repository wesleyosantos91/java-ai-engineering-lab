#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"

source "${SCRIPT_DIR}/../lib/app.sh" || exit 1
source "${SCRIPT_DIR}/../lib/lock.sh"
acquire_harness_lock || exit 1
source "${SCRIPT_DIR}/../lib/test-suite.sh"
# Testes ArchUnit pertencem a scripts/test/architecture.sh, não à suíte unitária.
TEST_SUITE_EXCLUDE='*ArchitectureTest.java'
# Classes *Tests (padrão do Spring Initializr) não seguem a convenção (ADR-0003) e não executam.
if [[ -d "${APP_ROOT}/src/test/java" ]]; then
  ignored="$(find "${APP_ROOT}/src/test/java" -type f -name '*Tests.java' | wc -l | tr -d ' ')"
  (( ignored == 0 )) ||
    echo "[AVISO] Unitários: ${ignored} classe(s) *Tests ignorada(s) pela convenção (*Test, *IT); renomeie-as." >&2
fi
run_test_suite "Unitários" '*Test.java' surefire-reports test
