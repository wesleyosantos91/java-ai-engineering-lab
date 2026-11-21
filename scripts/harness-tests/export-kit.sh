#!/usr/bin/env bash
set -Eeuo pipefail

# Prova que scripts/agents/export-kit.sh:
# - no modo padrão grava SOMENTE a configuração AI-First na raiz de um projeto existente
#   (app/, infra/ e .github/ intactos), detecta pacote e stack do app e passa no check-config
#   e no harness do destino;
# - com --seed gera o chassi (app/, infra/, tests/) que init-project.sh inicializa;
# - rejeita entradas inválidas sem alterar nada.

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
  hits="$(grep -rnIE --include='*.md' --include='*.java' --include='*.json' --include='*.yml' --include='*.yaml' \
    --include='CODEOWNERS' "${pattern}" "${dest}" || true)"
  if [[ -n "${hits}" ]]; then printf '%s\n' "${hits}" >&2; echo "[FAIL] resíduo: ${pattern}" >&2; exit 1; fi
  echo "[PASS] sem resíduo: ${pattern}"
}
tree_hash() { (cd "$1" && find . -type f -print0 | sort -z | xargs -0 sha1sum | sha1sum); }
commit() { git -C "$1" -c user.name=harness -c user.email=harness@example.invalid commit -qm "$2" --no-verify; }

# Projeto existente no layout padrão: app/ (Initializr), infra/ e .github/ do time de DevOps.
dest="${WORK}/projeto existente"
app="${dest}/app"
mkdir -p "${app}/src/main/java/com/acme/orders" "${app}/src/test/java/com/acme/orders" "${dest}/infra" "${dest}/.github"
cat > "${app}/pom.xml" <<'XML'
<project>
	<parent>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-parent</artifactId>
		<version>4.2.0</version>
	</parent>
	<groupId>com.acme</groupId>
	<artifactId>orders</artifactId>
	<properties><java.version>17</java.version></properties>
	<dependencies>
		<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-webmvc</artifactId></dependency>
		<dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-webmvc-test</artifactId></dependency>
	</dependencies>
</project>
XML
printf '#!/usr/bin/env bash\necho "mvn $*"\n' > "${app}/mvnw"
printf 'package com.acme.orders;\n\n@SpringBootApplication\npublic class OrdersApplication {}\n' \
  > "${app}/src/main/java/com/acme/orders/OrdersApplication.java"
printf 'package com.acme.orders;\nclass OrdersApplicationTests {}\n' > "${app}/src/test/java/com/acme/orders/OrdersApplicationTests.java"
printf 'resource "x" {}\n' > "${dest}/infra/main.tf"
printf '* @acme/devops\n' > "${dest}/.github/CODEOWNERS"
app_before="$(tree_hash "${app}")" infra_before="$(tree_hash "${dest}/infra")" github_before="$(tree_hash "${dest}/.github")"

expect 0 '[PASS] Kit exportado' bash "${EXPORT}" "${dest}" --project-name 'Orders Service'
grep -Fq 'classe OrdersApplication em com.acme.orders; Java 17; Spring Boot 4.2.0' "${WORK}/output"
grep -Fq 'Nada foi gravado em app/, infra/, tests/ nem .github/' "${WORK}/output"
assert test "$(tree_hash "${app}")" == "${app_before}"
assert test "$(tree_hash "${dest}/infra")" == "${infra_before}"
assert test "$(tree_hash "${dest}/.github")" == "${github_before}"
assert test ! -e "${dest}/pom.xml"
assert test ! -e "${dest}/src"
assert test ! -e "${dest}/tests"
assert test ! -e "${dest}/app/pom.xml.kit"
assert grep -qx 'APP_DIR=app' "${dest}/.harness"
assert grep -qx 'QUALITY_GATES=optional' "${dest}/.harness"
# Projeto autossuficiente: sem as ferramentas do kit e sem referência a este repositório ou ao seed.
assert test ! -e "${dest}/scripts/agents/export-kit.sh"
assert test ! -e "${dest}/scripts/harness-tests/export-kit.sh"
assert test ! -e "${dest}/scripts/agents/init-project.sh"
assert test ! -e "${dest}/scripts/lib/rename.sh"
none 'java-ai-first-seed|java-ai-engineering-lab|export-kit|init-project|herdad'
# Seções prontas: só os campos [PREENCHER-...] ficam para preencher, todos com responsável.
assert grep -qF -- '- Java 17, Spring Boot 4.2.0, Maven via Wrapper em `app/` (detectado em `app/pom.xml`; starters: webmvc).' "${dest}/AGENTS.md"
assert grep -q '^Propósito: \[PREENCHER-NEGÓCIO:' "${dest}/AGENTS.md"
assert grep -q '^- Persistência e integração: \[PREENCHER-ENGENHARIA:' "${dest}/AGENTS.md"
assert grep -qF '`list-pending.sh`, hooks; `check-prd.sh`' "${dest}/AGENTS.md"
assert grep -q '^## Revisão neste projeto' "${dest}/docs/architecture/adr/0001-architecture-principles.md"
assert grep -q '^## Revisão neste projeto' "${dest}/docs/architecture/adr/0003-test-suites-and-quality-gates.md"
assert grep -q 'Proposta (revisar)' "${dest}/docs/architecture/adr/README.md"
assert grep -q '^## Visão geral' "${dest}/README.md"
assert grep -q '^## Como executar' "${dest}/README.md"
gates_doc="${dest}/docs/how-to/enable-quality-gates.md"
assert grep -q '^## Blocos prontos para este projeto' "${gates_doc}"
assert grep -q '<app.basePackage>com.acme.orders</app.basePackage>' "${gates_doc}"
assert grep -q '<app.mainClass>OrdersApplication</app.mainClass>' "${gates_doc}"
assert grep -q '<artifactId>pitest-maven</artifactId>' "${gates_doc}"
assert grep -q '<artifactId>archunit</artifactId>' "${gates_doc}"
assert grep -q '^package com.acme.orders.architecture;' "${gates_doc}"
if grep -q 'spring-boot-maven-plugin\|<java.version>' "${gates_doc}"; then echo '[FAIL] bloco de pom com item que o app já tem' >&2; exit 1; fi
expect 3 'Projeto com' bash "${dest}/scripts/agents/list-pending.sh"
if grep -q 'Sem responsável' "${WORK}/output"; then cat "${WORK}/output"; echo '[FAIL] campo sem responsável' >&2; exit 1; fi
grep -Fq '    - AGENTS.md:' "${WORK}/output"
assert grep -q 'com.acme.orders' "${dest}/.agents/skills/architecture-guard/SKILL.md"
assert grep -q '^# Orders Service' "${dest}/README.md"
assert grep -q '"name": "orders-service"' "${dest}/.devcontainer/devcontainer.json"
assert grep -q '"Edit(./.github/\*\*)"' "${dest}/.claude/settings.json"
assert test -f "${dest}/docs/product/prd.md"
assert test -f "${dest}/docs/how-to/enable-quality-gates.md"
assert test -f "${dest}/.claude/skills/feature-delivery/SKILL.md"
assert grep -q 'Proposta — decidir na seção "Revisão neste projeto"' "${dest}/docs/architecture/adr/0001-architecture-principles.md"
none 'io\.github\.wesleyosantos91|wesleyosantos91/java-ai-engineering-lab|JavaAiEngineeringLab|Java AI Engineering Lab|Product Catalog'
none 'FEAT-0001-create-product|0004-ai-first|reference/api|LL-0[0-9]{3}|<!-- kit:'

# No destino como repositório Git próprio: arquivos sem espaços inválidos, check completo e
# harness (Maven simulado) com o app em app/.
git -C "${dest}" init -q
git -C "${dest}" add -A
expect 0 '' git -C "${dest}" diff --cached --check
expect 0 '[PASS] Configuração de agentes verificada.' bash "${dest}/scripts/agents/check-config.sh"
grep -Fq '[PASS] .harness válido (APP_DIR=app).' "${WORK}/output"
grep -Fq '[PASS] Arquivos do harness e dos agentes não estão ignorados pelo Git.' "${WORK}/output"
expect 0 '[PASS] Contratos do harness verificados' bash "${dest}/scripts/harness-tests/harness.sh"

# Reexportação: nada muda no app; arquivos de configuração alterados localmente viram .kit.
printf '\nAjuste local.\n' >> "${dest}/SECURITY.md"
expect 0 'SECURITY.md' bash "${EXPORT}" "${dest}" --project-name 'Orders Service'
assert test -f "${dest}/SECURITY.md.kit"
assert test "$(tree_hash "${app}")" == "${app_before}"

# Projeto sem app/: exporta a configuração e avisa que o harness exige app/pom.xml.
bare="${WORK}/sem app"
expect 0 'pom.xml AUSENTE' bash "${EXPORT}" "${bare}"
grep -Fq 'Pacote base não detectado' "${WORK}/output"
assert test ! -e "${bare}/app"

# Entradas inválidas não alteram nada.
expect 1 'Opção desconhecida: --base-package' bash "${EXPORT}" "${WORK}/x" --base-package com.acme
printf 'arquivo\n' > "${WORK}/um-arquivo"
expect 1 'não é diretório' bash "${EXPORT}" "${WORK}/um-arquivo"
expect 1 'dentro deste repositório' bash "${EXPORT}" "${ROOT_DIR}/docs/kit-fora-de-lugar"
assert test ! -e "${ROOT_DIR}/docs/kit-fora-de-lugar"
assert test ! -e "${WORK}/x"
expect 1 '--seed usa nomes fixos' bash "${EXPORT}" "${WORK}/y" --seed --project-name X
assert test ! -e "${WORK}/y"

# Seed público (--seed): chassi app/ compilável, infra/ e tests/, sem resíduos do produto. O
# README do seed aponta para este repositório de referência, por isso o slug fica de fora aqui.
dest="${WORK}/seed"
expect 0 '[PASS] Kit exportado' bash "${EXPORT}" "${dest}" --seed
none 'io\.github\.wesleyosantos91|JavaAiEngineeringLab|Java AI Engineering Lab|Product Catalog'
none 'FEAT-0001-create-product|0004-ai-first|reference/api|LL-0[0-9]{3}|<!-- kit:'
assert test ! -e "${dest}/pom.xml"
assert test ! -e "${dest}/.github"
assert test -f "${dest}/app/src/main/java/com/example/seed/SeedApplication.java"
assert test -f "${dest}/app/src/test/java/com/example/seed/SeedApplicationIT.java"
assert test -f "${dest}/app/src/test/java/com/example/seed/architecture/ArchitectureTest.java"
assert test -f "${dest}/app/src/main/resources/db/migration/.gitkeep"
assert test -f "${dest}/app/mvnw"
assert grep -q 'name: java-ai-first-seed' "${dest}/app/src/main/resources/application.yaml"
assert grep -q '<groupId>com.example</groupId>' "${dest}/app/pom.xml"
assert grep -q '<artifactId>java-ai-first-seed</artifactId>' "${dest}/app/pom.xml"
assert grep -q '<app.mainClass>SeedApplication</app.mainClass>' "${dest}/app/pom.xml"
assert test -f "${dest}/infra/README.md"
assert test -f "${dest}/tests/performance/k6/smoke.js"
assert grep -qx 'APP_DIR=app' "${dest}/.harness"
assert grep -qx 'QUALITY_GATES=required' "${dest}/.harness"
assert grep -qx 'Java AI-First Seed' <(head -n 1 "${dest}/NOTICE")
assert test -f "${dest}/LICENSE"
assert grep -q 'init-project.sh' "${dest}/README.md"
expect 3 'PRD em elaboração' bash "${dest}/scripts/product/check-prd.sh"

# init-project.sh no repositório criado a partir do template.
git -C "${dest}" init -q
git -C "${dest}" add -A
expect 0 '' git -C "${dest}" diff --cached --check
commit "${dest}" 'chore: seed'
init=("${dest}/scripts/agents/init-project.sh" --base-package com.acme.orders --main-class OrdersApplication)
expect 1 'Uso:' bash "${init[@]}"
expect 1 '--base-package inválido' bash "${dest}/scripts/agents/init-project.sh" --base-package Acme \
  --main-class OrdersApplication --project-name 'Orders Service'
touch "${dest}/sujo.txt"
expect 1 'Working tree com alterações' bash "${init[@]}" --project-name 'Orders Service'
rm "${dest}/sujo.txt"
expect 0 '[PASS] Orders Service inicializado' bash "${init[@]}" --project-name 'Orders Service'
none 'com\.example\.seed|com/example/seed|SeedApplication|java-ai-first-seed|Java AI-First Seed'
assert test -f "${dest}/app/src/main/java/com/acme/orders/OrdersApplication.java"
assert test -f "${dest}/app/src/test/java/com/acme/orders/OrdersApplicationIT.java"
assert test -f "${dest}/app/src/test/java/com/acme/orders/architecture/ArchitectureTest.java"
assert test ! -e "${dest}/app/src/main/java/com/example"
assert test ! -e "${dest}/src"
assert grep -q '<groupId>com.acme</groupId>' "${dest}/app/pom.xml"
assert grep -q '<artifactId>orders-service</artifactId>' "${dest}/app/pom.xml"
assert grep -q '<app.basePath>com/acme/orders</app.basePath>' "${dest}/app/pom.xml"
assert grep -q 'name: orders-service' "${dest}/app/src/main/resources/application.yaml"
assert grep -q '"name": "orders-service"' "${dest}/.devcontainer/devcontainer.json"
assert grep -q '^# Orders Service' "${dest}/README.md"
# Uso único: a inicialização se remove, e o projeto não depende do seed.
assert test ! -e "${dest}/scripts/agents/init-project.sh"
assert test ! -e "${dest}/scripts/lib/rename.sh"
assert test ! -e "${dest}/scripts/agents/export-kit.sh"
none 'init-project|export-kit|herdad'
assert grep -qF '`list-pending.sh`, hooks; `check-prd.sh`' "${dest}/AGENTS.md"
assert grep -q '^## Blocos prontos para este projeto' "${dest}/docs/how-to/enable-quality-gates.md"
assert grep -q '^package com.acme.orders.architecture;' "${dest}/docs/how-to/enable-quality-gates.md"
assert grep -q '^## Visão geral' "${dest}/README.md"
git -C "${dest}" add -A
expect 0 '' git -C "${dest}" diff --cached --check
commit "${dest}" 'chore: init'
expect 0 '[PASS] Configuração de agentes verificada.' bash "${dest}/scripts/agents/check-config.sh"
expect 0 '[PASS] Contratos do harness verificados' bash "${dest}/scripts/harness-tests/harness.sh"

echo "[PASS] Kit de adoção exportado e verificado em destinos temporários (removidos ao final)."
