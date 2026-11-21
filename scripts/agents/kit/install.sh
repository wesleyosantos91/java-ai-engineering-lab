#!/usr/bin/env bash
set -Eeuo pipefail

# Instalador do kit AI-First: aplica a configuração (instruções e skills dos agentes, harness,
# PRD guiado, ADRs propostos) na raiz de um monorepo existente, cujo projeto Maven está em app/.
#
# Uso: bash install.sh <diretório do projeto>
#
# - Detecta em app/ (só leitura): classe @SpringBootApplication, pacote, Java, Spring Boot, starters
#   e nome do projeto (<name> ou <artifactId> do app/pom.xml, ou o nome do diretório).
# - Nunca grava em app/, infra/, tests/, .github/ nem no README.md do projeto. Arquivo de
#   configuração que já existe e difere recebe a versão do kit como <arquivo>.kit.
# - Monta tudo numa área temporária e roda o check-config nela antes de tocar o projeto.
# - Nada deste instalador (install.sh, payload/, templates/, lib/) é copiado para o projeto.
# Retornos: 0 = configuração aplicada e verificada; 1 = erro (projeto intacto).

KIT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
PAYLOAD="${KIT_DIR}/payload"
TEMPLATES="${KIT_DIR}/templates"
source "${KIT_DIR}/lib/rename.sh"

# Marcadores neutros gravados no payload pelo exportador; trocados pelos valores detectados.
KIT_PACKAGE=com.example.kitapp
KIT_MAIN=KitMainApplication
KIT_NAME='@@PROJECT_NAME@@'
KIT_SLUG='@@PROJECT_SLUG@@'
APP=app

usage() { echo "Uso: bash install.sh <diretório do projeto>" >&2; exit 1; }
(( $# == 1 )) || usage
case "$1" in -*) usage ;; esac
[[ -d "${PAYLOAD}" && -d "${TEMPLATES}" && -s "${KIT_DIR}/VERSION" ]] || {
  echo "[FAIL] Kit incompleto em ${KIT_DIR} (payload/, templates/ ou VERSION ausente)." >&2; exit 1; }
KIT_VERSION="$(head -n 1 "${KIT_DIR}/VERSION" | tr -d '[:space:]')"
[[ -d "$1" ]] || { echo "[FAIL] Diretório do projeto não encontrado: $1" >&2; exit 1; }
DEST="$(cd -- "$1" && pwd -P)"
case "${DEST}/" in
  "${KIT_DIR}/"*) echo "[FAIL] O projeto não pode estar dentro do kit: ${DEST}" >&2; exit 1 ;;
esac

# 1. Projeto existente: app/pom.xml e a classe @SpringBootApplication são obrigatórios.
pom="${DEST}/${APP}/pom.xml"
[[ -f "${pom}" ]] || {
  echo "[FAIL] ${APP}/pom.xml não encontrado em ${DEST}: o kit configura um monorepo existente com o projeto Maven em ${APP}/." >&2
  exit 1
}
main_file="$(grep -rlE '^@SpringBootApplication' "${DEST}/${APP}/src/main/java" --include='*.java' 2>/dev/null | sort | head -n 1 || true)"
[[ -n "${main_file}" ]] || {
  echo "[FAIL] Classe @SpringBootApplication não encontrada em ${APP}/src/main/java." >&2; exit 1; }
main_class="$(basename -- "${main_file}" .java)"
package="$(sed -n 's/^package \([a-zA-Z0-9_.]*\);.*/\1/p' "${main_file}" | head -n 1)"
[[ "${package}" =~ ^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$ ]] || {
  echo "[FAIL] Pacote não reconhecido em ${main_file#"${DEST}"/}." >&2; exit 1; }
# Elemento do projeto (não do <parent>): primeiro valor após </parent>.
project_tag() { awk -v tag="$1" '/<\/parent>/ { after = 1; next }
  after && $0 ~ "<" tag ">" { v = $0; sub(".*<" tag ">", "", v); sub("</" tag ">.*", "", v); print v; exit }' "${pom}"; }
java_version="$(sed -n 's#.*<java.version>\([^<]*\)</java.version>.*#\1#p' "${pom}" | head -n 1)"
boot_version="$(awk '/<parent>/,/<\/parent>/' "${pom}" | sed -n 's#.*<version>\([^<]*\)</version>.*#\1#p' | head -n 1)"
starters="$(sed -n 's#.*<artifactId>spring-boot-starter-\([a-z-]*\)</artifactId>.*#\1#p' "${pom}" |
  grep -v -e '-test$' -e '^parent$' | sort -u | paste -sd, - | sed 's/,/, /g' || true)"
name="$(project_tag name)"
[[ -n "${name}" ]] || name="$(project_tag artifactId)"
[[ -n "${name}" ]] || name="$(basename -- "${DEST}")"
slug="$(project_slug "${name}")"

STAGE="$(mktemp -d)"
trap 'rm -rf "${STAGE}"' EXIT
cp -R "${PAYLOAD}/." "${STAGE}/"

# 2. Valores do projeto no lugar dos marcadores neutros (só nos textos da configuração).
rename_package "${STAGE}" "${KIT_PACKAGE}" "${package}"
rename_literal "${STAGE}" "${KIT_MAIN}" "${main_class}"
rename_literal "${STAGE}" "${KIT_NAME}" "${name}"
rename_literal "${STAGE}" "${KIT_SLUG}" "${slug:-app}"

# 3. AGENTS.md §2: stack detectada; a engenharia completa só a persistência.
if [[ -n "${java_version}" && -n "${boot_version}" ]]; then
  stack="- Java ${java_version}, Spring Boot ${boot_version}, Maven via Wrapper em \`${APP}/\` (detectado em \`${APP}/pom.xml\`; starters: ${starters:-nenhum})."
else
  stack="- [PREENCHER-ENGENHARIA: versões de Java e Spring Boot (não detectadas em ${APP}/pom.xml)]; Maven via Wrapper em \`${APP}/\`."
fi
persistence='- Persistência e integração: [PREENCHER-ENGENHARIA: banco, migrações e testes de integração; os ADRs propostos sugerem Spring JDBC, PostgreSQL, Flyway e Testcontainers].'
awk -v stack="${stack}" -v persistence="${persistence}" '
  /^- Java [0-9]+, Spring Boot / { print stack; next }
  /^- Spring JDBC com SQL explícito/ { print persistence; next }
  { print }' "${STAGE}/AGENTS.md" > "${STAGE}/AGENTS.md.tmp" && mv "${STAGE}/AGENTS.md.tmp" "${STAGE}/AGENTS.md"

# 3b. Devcontainer com o Java do app (a feature aceita a versão principal, como "17").
if [[ "${java_version}" =~ ^[0-9]+$ ]]; then
  sed -i -e "/features\/java:/,/}/ s/\"version\": \"[^\"]*\"/\"version\": \"${java_version}\"/" \
    -e "s/Java [0-9][0-9]* (Temurin, patch fixado; atualize deliberadamente)/Java ${java_version} (Temurin; versão do app\/pom.xml)/" \
    "${STAGE}/.devcontainer/devcontainer.json"
fi

# 4. Guia de quality gates com os blocos prontos para o pacote e a classe do projeto.
path="${package//.//}"
adapt() { sed -e "s#${KIT_PACKAGE//./\\.}#${package}#g" -e "s#${KIT_PACKAGE//.//}#${path}#g" -e "s#${KIT_MAIN}#${main_class}#g"; }
code() { printf '\n```%s\n' "$1"; cat; printf '```\n'; }
deps='archunit|junit-platform-launcher|spring-boot-testcontainers|testcontainers-junit-jupiter|testcontainers-postgresql'
{
  printf '\n## Blocos prontos para este projeto\n\n'
  printf 'Gerados para o pacote `%s` e a classe `%s`. Copie cada bloco para o lugar indicado e ajuste só o que o projeto não usar.\n' "${package}" "${main_class}"
  printf '\n### 1. `app/pom.xml`: propriedades (dentro de `<properties>`)\n'
  awk '/<properties>/ { on = 1; next } /<\/properties>/ { on = 0 } on && !/<java.version>/' "${TEMPLATES}/pom.xml" | adapt | code xml
  printf '\n### 2. `app/pom.xml`: dependências de teste (dentro de `<dependencies>`)\n\nSe o app não usa banco, omita as três dependências de Testcontainers.\n'
  awk -v deps="^(${deps})$" '
    /<dependency>/ { block = ""; on = 1 }
    on { block = block $0 "\n" }
    on && /<artifactId>/ { id = $0; gsub(/.*<artifactId>|<\/artifactId>.*/, "", id) }
    /<\/dependency>/ && on { if (id ~ deps) printf "%s", block; on = 0 }' "${TEMPLATES}/pom.xml" | code xml
  printf '\n### 3. `app/pom.xml`: plugins (dentro de `<build><plugins>`)\n'
  awk '
    /<plugin>/ && depth == 0 { block = ""; on = 1 }
    on { block = block $0 "\n" }
    on && /<artifactId>spring-boot-maven-plugin<\/artifactId>/ { skip = 1 }
    /<plugin>/ { depth++ } /<\/plugin>/ { depth-- }
    on && depth == 0 { if (!skip) printf "%s", block; on = 0; skip = 0 }' "${TEMPLATES}/pom.xml" | adapt | code xml
  printf '\n### 4. Classes de teste em `app/src/test/java/%s/`\n' "${path}"
  for file in architecture/ArchitectureTest.java TestcontainersConfiguration.java "${KIT_MAIN}IT.java" "Test${KIT_MAIN}.java"; do
    [[ -f "${TEMPLATES}/test/${file}" ]] || continue
    printf '\n`%s`:\n' "$(adapt <<<"${file}")"
    adapt < "${TEMPLATES}/test/${file}" | code java
  done
  printf '\nSem banco, troque `%sIT` por um teste de contexto sem Testcontainers e não crie `TestcontainersConfiguration` nem `Test%s`:\n' "${main_class}" "${main_class}"
  printf 'package %s;\n\nimport org.junit.jupiter.api.Test;\nimport org.springframework.boot.test.context.SpringBootTest;\n\n@SpringBootTest\nclass %sIT {\n\n\t@Test\n\tvoid contextLoads() {\n\t}\n\n}\n' \
    "${package}" "${main_class}" | code java
  printf '\n### 5. Ativar\n\nCom os blocos aplicados e `bash scripts/verify.sh` verde, troque `QUALITY_GATES=optional` por `QUALITY_GATES=required` no `.harness`.\n'
} >> "${STAGE}/docs/how-to/enable-quality-gates.md"

# 5. .harness do projeto: Maven em app/, gates opcionais até o app/pom.xml ser configurado. Numa
#    reinstalação, o QUALITY_GATES escolhido pelo projeto é preservado e só a versão do kit muda.
harness_value() { [[ -f "${DEST}/.harness" ]] && sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*\([^[:space:]#]*\).*/\1/p" "${DEST}/.harness" | tail -n 1; }
previous_version="$(harness_value KIT_VERSION || true)"
gates="$(harness_value QUALITY_GATES || true)"
[[ "${gates}" == required ]] || gates=optional
cat > "${STAGE}/.harness" <<EOF
# Configuração do harness (scripts/lib/app.sh); chave=valor, sem execução de código.
# APP_DIR: projeto Maven, sempre app/ (docs/architecture/repository-layout.md).
# QUALITY_GATES: optional = gate não configurado em app/pom.xml é SKIP; required = FAIL.
#   Para ativar, veja docs/how-to/enable-quality-gates.md ou bash scripts/quality/enable-gates.sh.
# REPOSITORY_ROLE: project exige APP_DIR=app (verificado por scripts/agents/check-config.sh).
# KIT_VERSION: versão do kit AI-First aplicada; o instalador a atualiza a cada reinstalação.
APP_DIR=${APP}
QUALITY_GATES=${gates}
REPOSITORY_ROLE=project
KIT_VERSION=${KIT_VERSION}
EOF

# 6. Só configuração: nada sob app/, infra/, tests/ ou .github/, e o README.md é do projeto.
forbidden="$(cd "${STAGE}" && find "${APP}" infra tests .github README.md -type f 2>/dev/null | head -n 5 || true)"
if [[ -n "${forbidden}" ]]; then
  printf '%s\n' "${forbidden}" >&2
  echo "[FAIL] O kit só grava configuração; não pode gravar em ${APP}/, infra/, tests/, .github/ ou README.md." >&2
  exit 1
fi

# 7. Stubs do Claude Code e verificação antes de tocar o projeto. O app/ vazio na área temporária
#    só satisfaz a validação do .harness (diretórios vazios não são copiados). O README.md do
#    projeto entra na área temporária só para validar o link do AGENTS.md (idêntico: não é
#    copiado de volta); sem README, a linha que aponta para ele sai do AGENTS.md.
bash "${STAGE}/scripts/agents/sync-skills.sh" >/dev/null
mkdir -p "${STAGE}/${APP}"
if [[ -f "${DEST}/README.md" ]]; then
  cp -p "${DEST}/README.md" "${STAGE}/README.md"
else
  sed -i '/^| Navegação geral | \[README.md\](README.md) |$/d' "${STAGE}/AGENTS.md"
fi
if ! check_output="$(cd "${STAGE}" && bash scripts/agents/check-config.sh 2>&1)"; then
  printf '%s\n' "${check_output}" >&2
  echo "[FAIL] A configuração gerada não passou em agents/check-config.sh; projeto não alterado." >&2
  exit 1
fi

# 8. Cópia. O .kit-manifest registra o hash de cada arquivo que o kit instalou: numa atualização,
#    arquivo ainda idêntico ao instalado é atualizado no lugar; arquivo alterado pelo projeto (ou
#    sem registro) não é sobrescrito, e a versão nova fica ao lado como <arquivo>.kit. O .harness,
#    já mesclado acima com os valores do projeto, é atualizado no lugar.
MANIFEST=.kit-manifest
declare -A installed=()
if [[ -f "${DEST}/${MANIFEST}" ]]; then
  while read -r hash path; do
    [[ -n "${path}" && "${hash}" != '#'* ]] && installed["${path}"]="${hash}"
  done < "${DEST}/${MANIFEST}"
fi
sha1() { sha1sum < "$1" | cut -d' ' -f1; }
conflicts=() copied=0 refreshed=0 updated=0 manifest_lines=()
while IFS= read -r -d '' file; do
  rel="${file#"${STAGE}"/}"
  [[ "${rel}" != README.md ]] || continue
  target="${DEST}/${rel}"
  mkdir -p "$(dirname -- "${target}")"
  [[ "${rel}" == .harness ]] || manifest_lines+=("$(sha1 "${file}") ${rel}")
  if [[ "${rel}" == .harness && -e "${target}" ]]; then
    cmp -s "${file}" "${target}" || { cp -p "${file}" "${target}"; updated=1; }
  elif [[ -e "${target}" ]]; then
    cmp -s "${file}" "${target}" && continue
    if [[ -n "${installed[${rel}]:-}" && "${installed[${rel}]}" == "$(sha1 "${target}")" ]]; then
      cp -p "${file}" "${target}"
      refreshed=$((refreshed + 1))
    else
      cp -p "${file}" "${target}.kit"
      conflicts+=("${rel}")
    fi
  else
    cp -p "${file}" "${target}"
    copied=$((copied + 1))
  fi
done < <(find "${STAGE}" -type f -print0 | sort -z)
{
  echo "# Arquivos instalados pelo kit AI-First ${KIT_VERSION} (sha1 e caminho). Não edite: o instalador"
  echo "# usa este registro para atualizar só o que o projeto não alterou. Versione junto com o projeto."
  printf '%s\n' "${manifest_lines[@]}"
} > "${DEST}/${MANIFEST}"

echo "[PASS] Configuração AI-First aplicada em ${DEST}: ${copied} arquivo(s) novo(s), ${refreshed} atualizado(s); check-config aprovado."
if [[ -n "${previous_version}" || "${updated}" == 1 ]]; then
  echo "[INFO] Atualização do kit: ${previous_version:-versão não registrada} -> ${KIT_VERSION}; .harness atualizado com QUALITY_GATES=${gates} preservado."
else
  echo "[INFO] Kit ${KIT_VERSION} (registrado em .harness, KIT_VERSION)."
fi
if (( ${#conflicts[@]} > 0 )); then
  echo "[AVISO] ${#conflicts[@]} arquivo(s) alterado(s) no projeto (ou sem registro no .kit-manifest); a versão nova do kit está em <arquivo>.kit para mesclar:"
  printf '  - %s\n' "${conflicts[@]}"
fi
echo "[INFO] Detectado em ${APP}/: projeto \"${name}\"; classe ${main_class} em ${package}; Java ${java_version:-?}; Spring Boot ${boot_version:-?}; starters: ${starters:-nenhum}."
echo "[INFO] Nada foi gravado em ${APP}/, infra/, tests/, .github/ nem no README.md."
echo "[INFO] Próximos passos (seções prontas; só os campos [PREENCHER-...] ficam para preencher):"
echo "  - Negócio: docs/product/prd.md (bash scripts/product/check-prd.sh) e propósito no AGENTS.md §1."
echo "  - Engenharia: seção \"Revisão neste projeto\" dos ADRs 0001 a 0003, AGENTS.md §2 (persistência) e licença no CONTRIBUTING.md."
echo "  - Quality gates: blocos prontos no fim de docs/how-to/enable-quality-gates.md; depois QUALITY_GATES=required no .harness."
echo "  - Harness: git init (se preciso), bash scripts/git/install-hooks.sh e bash scripts/verify.sh."
pending="$( (cd "${DEST}" && bash scripts/agents/list-pending.sh) | grep -E '^  [^ ]' || true)"
[[ -z "${pending}" ]] || { echo "  - Campos por responsável (lista completa: bash scripts/agents/list-pending.sh):"; sed 's/^/  /' <<<"${pending}"; }
