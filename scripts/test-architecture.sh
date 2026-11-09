#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

source "${SCRIPT_DIR}/lib/test-suite.sh"
# Execução Surefire dedicada (phase none): não roda no ciclo default, grava relatórios próprios
# e não usa o agent JaCoCo. Regras sem classes elegíveis são reportadas como ignoradas -> SKIP.
run_test_suite "Arquitetura" '*ArchitectureTest.java' architecture-reports \
  test-compile surefire:test@architecture
