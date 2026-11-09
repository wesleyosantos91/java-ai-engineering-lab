#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd -P)"

source "${SCRIPT_DIR}/lib/test-suite.sh"
# Percorrer até verify garante que falhas registradas pelo Failsafe afetem o exit code.
# skipUnitTests é exclusivo do Surefire; skipTests também afetaria Failsafe 3.5.x.
run_test_suite "Integração" '*IT.java' failsafe-reports -DskipUnitTests=true verify
