#!/usr/bin/env bash
# Compartilhado pelos scripts do harness; não deve ser executado diretamente.
# Trava de execução: impede dois fluxos do harness ao mesmo tempo no mesmo repositório (um
# `mvn clean` apagaria o target/ do outro). A trava é um diretório com o PID do dono, em
# .git/ (ou no diretório temporário, fora de um repositório Git). Exige ROOT_DIR definido.
#
# - Quem adquire exporta HARNESS_LOCK_HELD; scripts filhos (verify.sh -> unit.sh) não travam de novo.
# - Trava de processo encerrado é tomada automaticamente; não é preciso apagá-la à mão.
# - HARNESS_LOCK_DISABLE=1 desativa a trava (só para depuração; documentado em run-tests.md).
acquire_harness_lock() {
  [[ -z "${HARNESS_LOCK_HELD:-}" && "${HARNESS_LOCK_DISABLE:-0}" != 1 ]] || return 0
  local git_dir dir owner attempt
  # Compara caminhos normalizados (no Git Bash, o Git devolve C:/... e o shell, /c/...).
  local top
  if git_dir="$(git -C "${ROOT_DIR}" rev-parse --absolute-git-dir 2>/dev/null)" &&
     top="$(cd -- "$(git -C "${ROOT_DIR}" rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null && pwd -P)" &&
     [[ "${top}" == "$(cd -- "${ROOT_DIR}" && pwd -P)" ]]; then
    dir="${git_dir}/harness.lock"
  else
    dir="${TMPDIR:-/tmp}/harness-$(printf '%s' "${ROOT_DIR}" | cksum | cut -d' ' -f1).lock"
  fi
  for attempt in 1 2; do
    if mkdir "${dir}" 2>/dev/null; then
      printf '%s\n' "$$" > "${dir}/pid"
      export HARNESS_LOCK_HELD="${dir}"
      # Libera ao sair, preservando o trap EXIT que o script já tenha (chame depois de defini-lo).
      local previous
      previous="$(trap -p EXIT | sed -e "s/^trap -- '//" -e "s/' EXIT\$//")"
      # shellcheck disable=SC2064
      trap "${previous:+${previous}; }release_harness_lock" EXIT
      return 0
    fi
    owner="$(cat "${dir}/pid" 2>/dev/null || true)"
    if [[ "${owner}" =~ ^[0-9]+$ ]] && kill -0 "${owner}" 2>/dev/null; then
      echo "[FAIL] Outra execução do harness está em andamento neste repositório (PID ${owner}); aguarde o fim dela." >&2
      echo "       Trava: ${dir}" >&2
      return 1
    fi
    rm -rf "${dir}"
  done
  echo "[FAIL] Não foi possível adquirir a trava do harness: ${dir}" >&2
  return 1
}

# Libera a trava se ela pertence a este processo.
release_harness_lock() {
  local dir="${HARNESS_LOCK_HELD:-}"
  [[ -n "${dir}" && "$(cat "${dir}/pid" 2>/dev/null || true)" == "$$" ]] || return 0
  rm -rf "${dir}"
}
