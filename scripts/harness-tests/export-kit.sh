#!/usr/bin/env bash
set -Eeuo pipefail

# Prova o kit AI-First sobre um monorepo existente (app/ Maven, infra/ Terraform, tests/, .github/
# de CI e README do projeto):
# - scripts/agents/export-kit.sh <projeto> aplica só a configuração na raiz, detecta pacote, stack e
#   nome do projeto, não altera nada fora da configuração e passa no check-config e no harness;
# - --seed grava o instalador público, e bash <seed>/install.sh <projeto> produz o mesmo resultado
#   sem copiar nada do instalador para o projeto;
# - entradas inválidas não alteram nada.

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
  # Nenhuma ocorrência do padrão nos tipos de arquivo de conteúdo de <dir>.
  local dir="$1" pattern="$2" hits
  hits="$(grep -rnIE --include='*.md' --include='*.java' --include='*.json' --include='*.yml' --include='*.yaml' \
    --include='*.sh' --include='*.toml' "${pattern}" "${dir}" || true)"
  if [[ -n "${hits}" ]]; then printf '%s\n' "${hits}" >&2; echo "[FAIL] resíduo: ${pattern}" >&2; exit 1; fi
  echo "[PASS] sem resíduo: ${pattern}"
}
tree_hash() { (cd "$1" && find . -type f -print0 | sort -z | xargs -0 sha1sum | sha1sum); }
# Tudo o que é do projeto (e não configuração do kit): app/, infra/, tests/, .github/ e README.md.
project_hash() { (cd "$1" && find app infra tests .github README.md -type f -print0 | sort -z | xargs -0 sha1sum | sha1sum); }

# Monorepo existente no layout padrão, como o de um time real.
make_monorepo() {
  local dir="$1" app="$1/app"
  mkdir -p "${app}/src/main/java/com/acme/orders" "${app}/src/test/java/com/acme/orders" \
    "${dir}/infra/terraform" "${dir}/tests/e2e" "${dir}/.github/workflows"
  cat > "${app}/pom.xml" <<'XML'
<project>
	<parent>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-parent</artifactId>
		<version>4.2.0</version>
	</parent>
	<groupId>com.acme</groupId>
	<artifactId>orders</artifactId>
	<name>Orders Service</name>
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
  printf 'resource "aws_s3_bucket" "orders" {}\n' > "${dir}/infra/terraform/main.tf"
  printf 'GET http://localhost:8080/actuator/health\n' > "${dir}/tests/e2e/health.http"
  printf 'name: ci\non: [push]\n' > "${dir}/.github/workflows/ci.yml"
  printf '# Orders Service\n\nREADME do time.\n' > "${dir}/README.md"
}

# Verifica um projeto depois da instalação; $2 é o hash do projeto antes dela.
check_installed() {
  local dest="$1" before="$2"
  assert test "$(project_hash "${dest}")" == "${before}"
  assert test ! -e "${dest}/pom.xml"
  assert test ! -e "${dest}/install.sh"
  assert test ! -e "${dest}/payload"
  assert test ! -e "${dest}/templates"
  assert test ! -e "${dest}/scripts/agents/export-kit.sh"
  assert test ! -e "${dest}/scripts/agents/kit"
  assert test ! -e "${dest}/scripts/harness-tests/export-kit.sh"
  assert test ! -e "${dest}/README.md.kit"
  none "${dest}" 'io\.github\.wesleyosantos91|JavaAiEngineeringLab|Java AI Engineering Lab|Product Catalog'
  none "${dest}" 'FEAT-0001-create-product|0004-ai-first|reference/api|LL-0[0-9]{3}'
  if grep -rlq --include='*.md' -- '<!-- kit:' "${dest}"; then echo '[FAIL] marcador do kit em Markdown' >&2; exit 1; fi
  none "${dest}" 'java-ai-first-seed|java-ai-engineering-lab|export-kit|init-project|herdad|kitapp|KitMain|@@PROJECT'
  assert grep -qx 'APP_DIR=app' "${dest}/.harness"
  assert grep -qx 'QUALITY_GATES=optional' "${dest}/.harness"
  assert grep -qx 'REPOSITORY_ROLE=project' "${dest}/.harness"
  # Seções prontas, com os valores detectados.
  assert grep -q '^# AGENTS.md — Orders Service' "${dest}/AGENTS.md"
  assert grep -qF -- '- Java 17, Spring Boot 4.2.0, Maven via Wrapper em `app/` (detectado em `app/pom.xml`; starters: webmvc).' "${dest}/AGENTS.md"
  assert grep -q '^Propósito: \[PREENCHER-NEGÓCIO:' "${dest}/AGENTS.md"
  assert grep -q '^- Persistência e integração: \[PREENCHER-ENGENHARIA:' "${dest}/AGENTS.md"
  assert grep -q '^- Package base `com.acme.orders`' "${dest}/AGENTS.md"
  assert grep -qF '`list-pending.sh`, hooks; `check-prd.sh`' "${dest}/AGENTS.md"
  assert grep -qF '| Navegação geral | [README.md](README.md) |' "${dest}/AGENTS.md"
  assert grep -q 'com.acme.orders' "${dest}/.agents/skills/architecture-guard/SKILL.md"
  assert grep -q '"name": "orders-service"' "${dest}/.devcontainer/devcontainer.json"
  assert grep -q '"Edit(./.github/\*\*)"' "${dest}/.claude/settings.json"
  assert test -f "${dest}/.claude/skills/feature-delivery/SKILL.md"
  assert test -f "${dest}/docs/product/prd.md"
  assert grep -q '^## Revisão neste projeto' "${dest}/docs/architecture/adr/0001-architecture-principles.md"
  assert grep -q '^## Revisão neste projeto' "${dest}/docs/architecture/adr/0003-test-suites-and-quality-gates.md"
  assert grep -q 'Proposta (revisar)' "${dest}/docs/architecture/adr/README.md"
  local gates_doc="${dest}/docs/how-to/enable-quality-gates.md"
  assert grep -q '^## Blocos prontos para este projeto' "${gates_doc}"
  assert grep -q '<app.basePackage>com.acme.orders</app.basePackage>' "${gates_doc}"
  assert grep -q '<app.mainClass>OrdersApplication</app.mainClass>' "${gates_doc}"
  assert grep -q '<artifactId>pitest-maven</artifactId>' "${gates_doc}"
  assert grep -q '<artifactId>archunit</artifactId>' "${gates_doc}"
  assert grep -q '^package com.acme.orders.architecture;' "${gates_doc}"
  assert grep -qF '`OrdersApplicationIT.java`:' "${gates_doc}"
  if grep -q 'spring-boot-maven-plugin\|<java.version>' "${gates_doc}"; then echo '[FAIL] bloco com item que o app já tem' >&2; exit 1; fi
  expect 3 'Projeto com' bash "${dest}/scripts/agents/list-pending.sh"
  if grep -q 'Sem responsável' "${WORK}/output"; then cat "${WORK}/output"; echo '[FAIL] campo sem responsável' >&2; exit 1; fi
  # Repositório Git próprio: arquivos sem espaços inválidos, check completo e harness com app/.
  git -C "${dest}" init -q
  git -C "${dest}" add -A
  expect 0 '' git -C "${dest}" diff --cached --check
  expect 0 '[PASS] Configuração de agentes verificada.' bash "${dest}/scripts/agents/check-config.sh"
  grep -Fq '[PASS] .harness válido (APP_DIR=app).' "${WORK}/output"
  grep -Fq '[PASS] Arquivos do harness e dos agentes não estão ignorados pelo Git.' "${WORK}/output"
  expect 0 '[PASS] Contratos do harness verificados' bash "${dest}/scripts/harness-tests/harness.sh"
}

# 1. A partir deste repositório: só o diretório do projeto.
dest="${WORK}/monorepo"
make_monorepo "${dest}"
before="$(project_hash "${dest}")"
expect 0 '[PASS] Configuração AI-First aplicada' bash "${EXPORT}" "${dest}"
grep -Fq 'projeto "Orders Service"; classe OrdersApplication em com.acme.orders; Java 17; Spring Boot 4.2.0; starters: webmvc' "${WORK}/output"
grep -Fq 'Nada foi gravado em app/, infra/, tests/, .github/ nem no README.md.' "${WORK}/output"
check_installed "${dest}" "${before}"

# Reaplicação: nada muda no projeto; configuração alterada localmente recebe a versão do kit em .kit.
printf '\nAjuste local.\n' >> "${dest}/SECURITY.md"
expect 0 'SECURITY.md' bash "${EXPORT}" "${dest}"
assert test -f "${dest}/SECURITY.md.kit"
assert test "$(project_hash "${dest}")" == "${before}"

# Sem README no projeto: o AGENTS.md não aponta para um arquivo que não existe.
bare="${WORK}/sem readme"
make_monorepo "${bare}"
rm "${bare}/README.md"
expect 0 '[PASS] Configuração AI-First aplicada' bash "${EXPORT}" "${bare}"
assert test ! -e "${bare}/README.md"
if grep -qF '[README.md](README.md)' "${bare}/AGENTS.md"; then echo '[FAIL] link para README inexistente' >&2; exit 1; fi

# Entradas inválidas não alteram nada.
mkdir -p "${WORK}/sem app/infra"
expect 1 'app/pom.xml não encontrado' bash "${EXPORT}" "${WORK}/sem app"
assert test "$(find "${WORK}/sem app" -type f | wc -l)" -eq 0
expect 1 'Diretório do projeto não encontrado' bash "${EXPORT}" "${WORK}/inexistente"
assert test ! -e "${WORK}/inexistente"
expect 1 'Opção desconhecida: --project-name' bash "${EXPORT}" --project-name X "${dest}"
expect 1 'Uso:' bash "${EXPORT}" "${dest}" extra
printf 'arquivo\n' > "${WORK}/um-arquivo"
expect 1 'não é diretório' bash "${EXPORT}" "${WORK}/um-arquivo"
expect 1 'dentro deste repositório' bash "${EXPORT}" "${ROOT_DIR}/docs"

# 2. Seed: instalador público com a mesma configuração, sem nada deste produto.
seed="${WORK}/seed"
expect 0 '[PASS] Seed (instalador) gravado' bash "${EXPORT}" --seed "${seed}"
assert test -x "${seed}/install.sh"
assert test -f "${seed}/lib/rename.sh"
assert test -f "${seed}/payload/AGENTS.md"
assert test -f "${seed}/templates/pom.xml"
assert test -f "${seed}/LICENSE"
assert test ! -e "${seed}/app"
assert test ! -e "${seed}/payload/README.md"
assert test ! -e "${seed}/payload/.github"
assert grep -q 'bash java-ai-first-seed/install.sh /caminho/do/monorepo' "${seed}/README.md"
none "${seed}/payload" 'io\.github\.wesleyosantos91|JavaAiEngineeringLab|Java AI Engineering Lab|Product Catalog|java-ai-engineering-lab|java-ai-first-seed'
none "${seed}/templates" 'io\.github\.wesleyosantos91\.catalog|JavaAiEngineeringLab'
expect 1 'exige um diretório vazio' bash "${EXPORT}" --seed "${seed}"
expect 1 'Uso:' bash "${seed}/install.sh"
expect 1 'não pode estar dentro do kit' bash "${seed}/install.sh" "${seed}/payload"

# Instalação pelo seed, como um time faria depois do git clone.
dest="${WORK}/monorepo pelo seed"
make_monorepo "${dest}"
before="$(project_hash "${dest}")"
seed_before="$(tree_hash "${seed}")"
expect 0 '[PASS] Configuração AI-First aplicada' bash "${seed}/install.sh" "${dest}"
check_installed "${dest}" "${before}"
assert test "$(tree_hash "${seed}")" == "${seed_before}"

echo "[PASS] Kit AI-First aplicado e verificado em monorepos temporários (removidos ao final)."
