#!/usr/bin/env bash
set -Eeuo pipefail

# Prova que scripts/agents/export-kit.sh gera um kit autossuficiente: sem artefatos deste produto,
# com pacote e classe principal trocados, aprovado pelo check-config no destino e com o harness
# do destino funcionando. Também cobre destino com arquivos existentes e entradas inválidas.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
EXPORT="${ROOT_DIR}/scripts/agents/export-kit.sh"
mkdir -p "${ROOT_DIR}/target"
WORK="$(mktemp -d "${ROOT_DIR}/target/export-kit-check.XXXXXX")"
cleanup() { chmod -R u+w "${WORK}" 2>/dev/null || true; rm -rf "${WORK}"; }
trap cleanup EXIT

expect() {
  local expected="$1" message="$2" code=0
  shift 2
  "$@" > "${WORK}/output" 2>&1 || code=$?
  if [[ "${code}" != "${expected}" ]] || { [[ -n "${message}" ]] && ! grep -Fq -- "${message}" "${WORK}/output"; }; then
    cat "${WORK}/output"
    echo "[FAIL] esperado exit=${expected} e '${message}'; observado exit=${code}: $*" >&2
    exit 1
  fi
  echo "[PASS] exit=${code}; ${message}"
}
assert() { if "$@"; then echo "[PASS] $*"; else echo "[FAIL] $*" >&2; exit 1; fi; }
none() {
  # Nenhuma ocorrência do padrão nos tipos de arquivo de conteúdo (scripts citam os marcadores no código).
  local pattern="$1" hits
  hits="$(grep -rnIE --include='*.md' --include='*.java' --include='*.json' --include='*.yml' --include='CODEOWNERS' \
    "${pattern}" "${dest}" || true)"
  if [[ -n "${hits}" ]]; then printf '%s\n' "${hits}" >&2; echo "[FAIL] resíduo: ${pattern}" >&2; exit 1; fi
  echo "[PASS] sem resíduo: ${pattern}"
}

# Destino vazio, com pacote, classe e nome do projeto novos.
dest="${WORK}/novo repo"
expect 0 '[PASS] Kit exportado' bash "${EXPORT}" "${dest}" \
  --base-package com.acme.orders --main-class OrdersApplication --project-name 'Orders Service'
none 'io\.github\.wesleyosantos91|wesleyosantos91/java-ai'
none 'JavaAiEngineeringLab|Java AI Engineering Lab|Product Catalog'
none 'FEAT-0001-create-product|0004-ai-first|reference/api|LL-0[0-9]{3}'
none '<!-- kit:'
assert test -f "${dest}/src/test/java/com/acme/orders/architecture/ArchitectureTest.java"
assert grep -q '^package com.acme.orders.architecture;' "${dest}/src/test/java/com/acme/orders/architecture/ArchitectureTest.java"
assert test -f "${dest}/src/test/java/com/acme/orders/OrdersApplicationIT.java"
assert test ! -e "${dest}/src/main"
assert test ! -e "${dest}/docs/reference"
assert test ! -e "${dest}/docs/architecture/adr/0004-ai-first-reference-repository.md"
assert test ! -e "${dest}/LICENSE"
assert test -f "${dest}/docs/product/prd.md"
assert grep -q '^# Orders Service' "${dest}/README.md"
assert grep -q '<app.basePackage>com.acme.orders</app.basePackage>' "${dest}/pom.xml"
assert grep -q '"name": "orders-service"' "${dest}/.devcontainer/devcontainer.json"
assert grep -q 'Proposta (herdada do kit' "${dest}/docs/architecture/adr/0001-architecture-principles.md"
assert test -f "${dest}/.claude/skills/feature-delivery/SKILL.md"

# No destino como repositório Git próprio: arquivos sem espaços inválidos (o primeiro commit passa
# pelo pre-commit), check completo (inclui arquivos ignorados) e harness.
git -C "${dest}" init -q
git -C "${dest}" add -A
expect 0 '' git -C "${dest}" diff --cached --check
expect 0 '[PASS] Configuração de agentes verificada.' bash "${dest}/scripts/agents/check-config.sh"
grep -Fq '[PASS] Arquivos do harness e dos agentes não estão ignorados pelo Git.' "${WORK}/output"
expect 0 '[PASS] Contratos do harness verificados' bash "${dest}/scripts/harness-tests/harness.sh"

# Destino com arquivos existentes: nada é sobrescrito; a versão do kit vira <arquivo>.kit.
existing="${WORK}/existente"
mkdir -p "${existing}"
printf '# Meu projeto\n' > "${existing}/README.md"
printf '<project/>\n' > "${existing}/pom.xml"
expect 0 'pom.xml' bash "${EXPORT}" "${existing}"
assert grep -qx '# Meu projeto' "${existing}/README.md"
assert grep -qx '<project/>' "${existing}/pom.xml"
assert test -f "${existing}/pom.xml.kit"
assert test ! -e "${existing}/README.md.kit"
grep -Fq 'Pacote base mantido' "${WORK}/output"

# Entradas inválidas não alteram nada.
expect 1 '--base-package inválido' bash "${EXPORT}" "${WORK}/x" --base-package Com.Acme
expect 1 '--main-class inválido' bash "${EXPORT}" "${WORK}/x" --main-class orders
printf 'arquivo\n' > "${WORK}/um-arquivo"
expect 1 'não é diretório' bash "${EXPORT}" "${WORK}/um-arquivo"
expect 1 'dentro deste repositório' bash "${EXPORT}" "${ROOT_DIR}/docs/kit-fora-de-lugar"
assert test ! -e "${ROOT_DIR}/docs/kit-fora-de-lugar"
assert test ! -e "${WORK}/x"

# Seed público (--seed): chassi compilável com nomes neutros, sem resíduos do produto. O README
# do seed aponta para este repositório de referência, por isso o padrão do slug fica de fora aqui.
expect 1 '--seed usa nomes fixos' bash "${EXPORT}" "${WORK}/y" --seed --base-package com.acme.x
assert test ! -e "${WORK}/y"
dest="${WORK}/seed"
expect 0 '[PASS] Kit exportado' bash "${EXPORT}" "${dest}" --seed
none 'io\.github\.wesleyosantos91|JavaAiEngineeringLab|Java AI Engineering Lab|Product Catalog'
none 'FEAT-0001-create-product|0004-ai-first|reference/api|LL-0[0-9]{3}|<!-- kit:'
assert test -f "${dest}/src/main/java/com/example/seed/SeedApplication.java"
assert test -f "${dest}/src/test/java/com/example/seed/SeedApplicationIT.java"
assert test -f "${dest}/src/main/resources/db/migration/.gitkeep"
assert grep -q 'name: java-ai-first-seed' "${dest}/src/main/resources/application.yaml"
assert grep -q '<groupId>com.example</groupId>' "${dest}/pom.xml"
assert grep -q '<artifactId>java-ai-first-seed</artifactId>' "${dest}/pom.xml"
assert grep -q '<app.mainClass>SeedApplication</app.mainClass>' "${dest}/pom.xml"
assert grep -qx 'Java AI-First Seed' <(head -n 1 "${dest}/NOTICE")
assert test -f "${dest}/LICENSE"
assert grep -q 'init-project.sh' "${dest}/README.md"
expect 3 'PRD em elaboração' bash "${dest}/scripts/product/check-prd.sh"

# init-project.sh no repositório criado a partir do template.
git -C "${dest}" init -q
git -C "${dest}" add -A
expect 0 '' git -C "${dest}" diff --cached --check
git -C "${dest}" -c user.name=harness -c user.email=harness@example.invalid commit -qm 'chore: seed' --no-verify
init=("${dest}/scripts/agents/init-project.sh" --base-package com.acme.orders --main-class OrdersApplication)
expect 1 'Uso:' bash "${init[@]}"
expect 1 '--base-package inválido' bash "${dest}/scripts/agents/init-project.sh" --base-package Acme \
  --main-class OrdersApplication --project-name 'Orders Service'
touch "${dest}/sujo.txt"
expect 1 'Working tree com alterações' bash "${init[@]}" --project-name 'Orders Service'
rm "${dest}/sujo.txt"
expect 0 '[PASS] Orders Service inicializado' bash "${init[@]}" --project-name 'Orders Service'
none 'com\.example\.seed|com/example/seed|SeedApplication|java-ai-first-seed|Java AI-First Seed'
assert test -f "${dest}/src/main/java/com/acme/orders/OrdersApplication.java"
assert test -f "${dest}/src/test/java/com/acme/orders/OrdersApplicationIT.java"
assert test -f "${dest}/src/test/java/com/acme/orders/architecture/ArchitectureTest.java"
assert test ! -e "${dest}/src/main/java/com/example"
assert grep -q '<groupId>com.acme</groupId>' "${dest}/pom.xml"
assert grep -q '<artifactId>orders-service</artifactId>' "${dest}/pom.xml"
assert grep -q '<app.basePath>com/acme/orders</app.basePath>' "${dest}/pom.xml"
assert grep -q 'name: orders-service' "${dest}/src/main/resources/application.yaml"
assert grep -q '"name": "orders-service"' "${dest}/.devcontainer/devcontainer.json"
assert grep -q '^# Orders Service' "${dest}/README.md"
# Os scripts guardam os nomes do seed como constantes e não são reescritos.
assert grep -q '^SEED_PACKAGE=com.example.seed$' "${dest}/scripts/agents/init-project.sh"
assert grep -q 'seed/SeedApplication.java' "${dest}/scripts/harness-tests/export-kit.sh"
git -C "${dest}" add -A
expect 0 '' git -C "${dest}" diff --cached --check
git -C "${dest}" -c user.name=harness -c user.email=harness@example.invalid commit -qm 'chore: init' --no-verify
expect 1 'Projeto já inicializado' bash "${init[@]}" --project-name 'Orders Service'
expect 0 '[PASS] Contratos do harness verificados' bash "${dest}/scripts/harness-tests/harness.sh"

echo "[PASS] Kit de adoção exportado e verificado em destinos temporários (removidos ao final)."
