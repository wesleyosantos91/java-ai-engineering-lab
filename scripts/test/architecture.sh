#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"

source "${SCRIPT_DIR}/../lib/test-suite.sh"
# Execução Surefire dedicada (phase none): não roda no ciclo default, grava relatórios próprios
# e não usa o agent JaCoCo. Regras sem classes elegíveis usam o marcador [N/A] (ArchitectureTest)
# e contam como não aplicáveis; sem nenhuma regra aplicável executada, o resultado é SKIP.
TEST_SUITE_NA_MARKER='[N/A]'
run_test_suite "Arquitetura" '*ArchitectureTest.java' architecture-reports \
  test-compile surefire:test@architecture
