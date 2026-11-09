#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

source "${SCRIPT_DIR}/lib/test-suite.sh"
# Testes ArchUnit pertencem a scripts/test-architecture.sh, não à suíte unitária.
TEST_SUITE_EXCLUDE='*ArchitectureTest.java'
run_test_suite "Unitários" '*Test.java' surefire-reports test
