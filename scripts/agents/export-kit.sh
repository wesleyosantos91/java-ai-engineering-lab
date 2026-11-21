#!/usr/bin/env bash
set -Eeuo pipefail

# Exporta a configuração AI-First (instruções e skills dos agentes, harness, documentação de
# engenharia, PRD guiado) para a raiz de outro repositório. Guia: docs/how-to/adopt-in-new-repository.md.
#
# Uso: bash scripts/agents/export-kit.sh <destino> [--project-name <nome>]
#      bash scripts/agents/export-kit.sh <destino> --seed
#
# Layout de destino (docs/architecture/repository-layout.md): configuração na raiz e projeto Maven
# sempre em <destino>/app.
# - Padrão: SOMENTE configuração. Nada é gravado em app/, infra/, tests/ nem .github/ (gerido por
#   DevOps). O pacote e a classe principal são detectados no app (leitura) e usados nos textos.
#   Os quality gates ficam opcionais (.harness QUALITY_GATES=optional) até o pom do app ser
#   configurado (docs/how-to/enable-quality-gates.md).
# - --seed: configuração + chassi público (GitHub Template): app/ compilável com pacote
#   com.example.seed e classe SeedApplication, infra/, tests/, LICENSE/NOTICE e README de uso;
#   gates obrigatórios. scripts/agents/init-project.sh troca os nomes no repositório criado.
# - Arquivos que já existem no destino nunca são sobrescritos: a versão do kit é gravada como
#   <arquivo>.kit para mesclagem manual.
# - Marcadores nos Markdown (<!-- kit:omit-line -->, <!-- kit:replace-line: TEXTO -->,
#   <!-- kit:omit-start --> ... <!-- kit:omit-end -->) removem ou substituem trechos do projeto.
# Retornos: 0 = kit exportado e verificado; 1 = erro (destino intacto).

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
source "${SCRIPT_DIR}/../lib/app.sh" || exit 1
source "${SCRIPT_DIR}/../lib/pom.sh"
source "${SCRIPT_DIR}/../lib/rename.sh"

# Nomes do seed: init-project.sh os procura para renomear (não altere um sem o outro).
SEED_PACKAGE=com.example.seed
SEED_MAIN=SeedApplication
SEED_NAME='Java AI-First Seed'
SEED_SLUG=java-ai-first-seed
# Diretório do projeto Maven no destino (fixo: docs/architecture/repository-layout.md).
DEST_APP=app

usage() {
  echo "Uso: bash scripts/agents/export-kit.sh <destino> [--project-name <nome>]" >&2
  echo "     bash scripts/agents/export-kit.sh <destino> --seed" >&2
  exit 1
}

dest='' project_name='' seed=0
while (( $# )); do
  case "$1" in
    --project-name) [[ -n "${2:-}" ]] || usage; project_name="$2"; shift 2 ;;
    --seed) seed=1; shift ;;
    -h|--help) usage ;;
    -*) echo "[FAIL] Opção desconhecida: $1" >&2; usage ;;
    *) [[ -z "${dest}" ]] || usage; dest="$1"; shift ;;
  esac
done
[[ -n "${dest}" ]] || usage
if (( seed )) && [[ -n "${project_name}" ]]; then
  echo "[FAIL] --seed usa nomes fixos; personalize depois com scripts/agents/init-project.sh." >&2; exit 1
fi

# Origem: pacote, caminho e classe principal declarados no pom do app deste repositório.
old_package="$(pom_property app.basePackage)" || exit 1
old_path="$(pom_property app.basePath)" || exit 1
old_main="$(pom_property app.mainClass)" || exit 1

[[ ! -e "${dest}" || -d "${dest}" ]] || { echo "[FAIL] Destino existe e não é diretório: ${dest}" >&2; exit 1; }
# Resolve sem criar nada: o destino não pode ser este repositório nem ficar dentro dele
# (exceto em target/, usado pelos testes do harness).
DEST="$(realpath -m -- "${dest}")"
case "${DEST}/" in
  "${ROOT_DIR}/target/"*) ;;
  "${ROOT_DIR}/"*) echo "[FAIL] O destino não pode estar dentro deste repositório: ${DEST}" >&2; exit 1 ;;
esac

# Projeto de destino (modo padrão): somente leitura de <destino>/app.
detected_package='' detected_main='' java_version='' boot_version=''
if (( seed )); then
  new_package="${SEED_PACKAGE}" new_main="${SEED_MAIN}" project_name="${SEED_NAME}"
else
  dest_pom="${DEST}/${DEST_APP}/pom.xml"
  if [[ -f "${dest_pom}" ]]; then
    java_version="$(sed -n 's#.*<java.version>\([^<]*\)</java.version>.*#\1#p' "${dest_pom}" | head -n 1)"
    boot_version="$(awk '/<parent>/,/<\/parent>/' "${dest_pom}" | sed -n 's#.*<version>\([^<]*\)</version>.*#\1#p' | head -n 1)"
  fi
  if [[ -d "${DEST}/${DEST_APP}/src/main/java" ]]; then
    main_file="$(grep -rlE '^@SpringBootApplication' "${DEST}/${DEST_APP}/src/main/java" --include='*.java' | sort | head -n 1 || true)"
    if [[ -n "${main_file}" ]]; then
      detected_main="$(basename -- "${main_file}" .java)"
      detected_package="$(sed -n 's/^package \([a-zA-Z0-9_.]*\);.*/\1/p' "${main_file}" | head -n 1)"
    fi
  fi
  new_package="${detected_package:-com.example.app}" new_main="${detected_main:-Application}"
fi

STAGE="$(mktemp -d)"
trap 'rm -rf "${STAGE}"' EXIT

# 1. Configuração AI-First: somente arquivos versionáveis (rastreados ou novos não ignorados).
#    Sem .github/ (DevOps), sem código do app e sem artefatos deste produto.
include=(
  AGENTS.md CLAUDE.md CONTRIBUTING.md SECURITY.md
  .agents .claude/settings.json .codex .devcontainer scripts
  .editorconfig .gitattributes .gitignore .gitleaks.toml
  docs/ai docs/engineering docs/how-to/run-tests.md docs/how-to/enable-quality-gates.md
  docs/architecture/package-conventions.md docs/architecture/dependency-rules.md
  docs/architecture/repository-layout.md
  docs/architecture/adr/README.md docs/architecture/adr/TEMPLATE.md
  docs/architecture/adr/0001-architecture-principles.md
  docs/architecture/adr/0002-multi-provider-agent-context.md
  docs/architecture/adr/0003-test-suites-and-quality-gates.md
  docs/features/README.md docs/features/TEMPLATE.md docs/product/TEMPLATE.md
)
(cd "${ROOT_DIR}" && git ls-files -z --cached --others --exclude-standard -- "${include[@]}" |
  tar --null -T - -cf -) | (cd "${STAGE}" && tar -xf -)
# Ferramentas do kit ficam neste repositório: o projeto gerado não depende delas. O seed leva só a
# inicialização (init-project.sh e rename.sh), que se remove depois de executada.
rm -f "${STAGE}/scripts/agents/export-kit.sh" "${STAGE}/scripts/harness-tests/export-kit.sh"
(( seed )) || rm -f "${STAGE}/scripts/agents/init-project.sh" "${STAGE}/scripts/lib/rename.sh"

# 2. Marcadores do kit em todos os Markdown.
while IFS= read -r -d '' file; do
  awk '
    /<!-- kit:omit-start -->/ { skip = 1; next }
    /<!-- kit:omit-end -->/ { skip = 0; next }
    skip { next }
    /<!-- kit:omit-line -->/ { next }
    # Linhas em branco só são emitidas antes de conteúdo: um bloco omitido no fim do arquivo
    # não deixa linha em branco sobrando (git diff --check no repositório novo).
    function emit(text) { for (; blanks > 0; blanks--) print ""; print text }
    /<!-- kit:replace-line: / {
      text = $0; sub(/.*<!-- kit:replace-line: /, "", text); sub(/ -->.*/, "", text); emit(text); next
    }
    /^[ \t\r]*$/ { blanks++; next }
    { emit($0) }' "${file}" > "${file}.tmp" && mv "${file}.tmp" "${file}"
done < <(find "${STAGE}" -type f -name '*.md' -print0)

# 3. ADRs iniciais entram como Proposta, com a seção de revisão pronta para o projeto decidir.
proposed='Proposta — decidir na seção "Revisão neste projeto"'
adr_dir="${STAGE}/docs/architecture/adr"
sed -i "/^## Status$/,/^## / s/^Aceita$/${proposed}/" "${adr_dir}/0001-architecture-principles.md"
sed -i "s/^- \*\*Status:\*\* Proposta$/- **Status:** ${proposed}/; s/^- \*\*Responsável pela decisão:\*\* .*/- **Responsável pela decisão:** ver \"Revisão neste projeto\"/" \
  "${adr_dir}"/000[23]-*.md
sed -i -E 's/^(\| \[000[1-3]\]\([^)]*\) \| [^|]* \| )[^|]*( \| )[^|]*( \|)$/\1Proposta (revisar)\2—\3/' "${adr_dir}/README.md"
for adr in "${adr_dir}"/000[1-3]-*.md; do
  cat >> "${adr}" <<'EOF'

## Revisão neste projeto

> **Quem preenche:** Engenharia · **Obrigatória** antes da primeira feature. Registre a decisão aqui e no [índice](README.md). Para mudar o conteúdo da decisão, registre um novo ADR que a substitua.

| Campo | Valor |
|---|---|
| Decisão | [PREENCHER-ENGENHARIA: Aceita, Rejeitada ou Substituída por ADR-NNNN] |
| Responsável | [PREENCHER-ENGENHARIA: nome e papel] |
| Data | [PREENCHER-ENGENHARIA: AAAA-MM-DD] |
| Ajustes para este projeto | [PREENCHER-ENGENHARIA: diferenças de stack ou de escopo, ou "Nenhum"] |
EOF
done

# 4. PRD inicial a partir do template.
cp "${STAGE}/docs/product/TEMPLATE.md" "${STAGE}/docs/product/prd.md"

# 5. Seed: chassi do app e diretórios de projeto, montados sob app/, infra/ e tests/.
write_seed_chassis() {
  local app="${STAGE}/${DEST_APP}" main_dir resources
  mkdir -p "${app}"
  # Build e testes de infraestrutura do app de origem, já no caminho app/.
  (cd "${APP_ROOT}" && git ls-files -z --cached --others --exclude-standard -- \
    pom.xml mvnw mvnw.cmd .mvn \
    "src/test/java/${old_path}/TestcontainersConfiguration.java" \
    "src/test/java/${old_path}/${old_main}IT.java" \
    "src/test/java/${old_path}/Test${old_main}.java" \
    "src/test/java/${old_path}/architecture" | tar --null -T - -cf -) | (cd "${app}" && tar -xf -)
  main_dir="${app}/src/main/java/${old_path}" resources="${app}/src/main/resources"
  mkdir -p "${main_dir}" "${resources}/db/migration"
  cat > "${main_dir}/${old_main}.java" <<EOF
package ${old_package};

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ${old_main} {

	public static void main(String[] args) {
		SpringApplication.run(${old_main}.class, args);
	}

}
EOF
  cat > "${resources}/application.yaml" <<EOF
spring:
  application:
    name: ${SEED_SLUG}
  jackson:
    deserialization:
      # Propriedades JSON desconhecidas são rejeitadas, nunca ignoradas (ajuste conforme o PRD).
      fail-on-unknown-properties: true
  mvc:
    problemdetails:
      enabled: true
EOF
  : > "${resources}/db/migration/.gitkeep"
  # Identidade do projeto: groupId e artifactId logo após o <parent>.
  sed -i "/<\/parent>/,/<artifactId>/ { s#<groupId>[^<]*</groupId>#<groupId>com.example</groupId>#; s#<artifactId>[^<]*</artifactId>#<artifactId>${SEED_SLUG}</artifactId>#; }" \
    "${app}/pom.xml"

  # Cenário k6 de disponibilidade em tests/ (fora do app).
  mkdir -p "${STAGE}/tests/performance/k6" "${STAGE}/infra"
  cp "${ROOT_DIR}/tests/performance/k6/smoke.js" "${STAGE}/tests/performance/k6/smoke.js"
  cat > "${STAGE}/infra/README.md" <<'EOF'
# infra

Infraestrutura como código, compose e configuração de ambiente consumidos pelos pipelines. Regras para agentes e verificações: [layout do repositório](../docs/architecture/repository-layout.md).
EOF
  cat > "${STAGE}/tests/README.md" <<'EOF'
# tests

Testes que ficam fora do projeto Maven, executados pelo harness ou pelos pipelines. `performance/k6/smoke.js` é o smoke de disponibilidade de `bash scripts/performance/smoke.sh`. Testes unitários, de arquitetura e de integração ficam em `app/src/test/java`. Regras: [layout do repositório](../docs/architecture/repository-layout.md).
EOF

  [[ -f "${ROOT_DIR}/LICENSE" && -f "${ROOT_DIR}/NOTICE" ]] ||
    { echo "[FAIL] --seed exige LICENSE e NOTICE na raiz do repositório de origem." >&2; exit 1; }
  cp "${ROOT_DIR}/LICENSE" "${STAGE}/LICENSE"
  sed "1s/.*/${SEED_NAME}/" "${ROOT_DIR}/NOTICE" > "${STAGE}/NOTICE"
  cat > "${STAGE}/README.md" <<'EOF'
# Java AI-First Seed

Chassi de contexto para projetos Java desenvolvidos com agentes de IA (Codex, Claude Code, Devin). Não contém regra de negócio: traz as instruções dos agentes, as skills, o harness de verificação, os quality gates e um PRD guiado para o time de negócio preencher.

## Estrutura

| Diretório | Conteúdo |
|---|---|
| Raiz: [AGENTS.md](AGENTS.md), `.agents/`, `.claude/`, `.codex/`, `docs/`, `scripts/`, `.harness` | Configuração AI-First, que vale para o repositório inteiro |
| `app/` | Projeto Maven: Spring Boot 4, Java 27, Spring JDBC, PostgreSQL, Flyway, Testcontainers; sem endpoints |
| `infra/` | Infraestrutura como código e configuração de ambiente |
| `tests/` | Testes fora do app (smoke k6 em `tests/performance/k6/`) |
| `.github/` | Não vem no seed: workflows, CODEOWNERS e templates são configurados pelo time de DevOps, e agentes não os alteram |

Detalhes e regras por diretório: [layout do repositório](docs/architecture/repository-layout.md).

## Como começar

1. **Criar o repositório:** botão *Use this template* no GitHub e clone do novo repositório.
2. **Dar nome ao projeto** (pacote, classe principal, identidade Maven em `app/pom.xml` e este README):

   ```bash
   bash scripts/agents/init-project.sh --base-package com.acme.orders \
     --main-class OrdersApplication --project-name "Orders Service"
   ```

3. **Time de negócio: preencher o PRD** em [docs/product/prd.md](docs/product/prd.md). Cada seção diz quem a preenche (`Negócio`, `Engenharia` ou `Ambos`) e se é obrigatória; os campos pendentes aparecem como `[PREENCHER-NEGÓCIO: ...]` e `[PREENCHER-ENGENHARIA: ...]`. Para ver o que falta, por responsável:

   ```bash
   bash scripts/product/check-prd.sh
   ```

   O PRD só pode ser marcado como **Aprovado** sem pendências; a verificação dos agentes falha caso contrário.

4. **Engenharia:** complete as seções técnicas do PRD, ajuste o `AGENTS.md` (§1 propósito, §2 stack), revise os ADRs herdados e a licença.
5. **Ativar o harness:**

   ```bash
   bash scripts/git/install-hooks.sh
   bash scripts/setup.sh
   bash scripts/verify.sh
   ```

   Sem código de negócio, unitários e cobertura retornam SKIP e o resultado é PARCIAL. É o esperado até a primeira feature.

6. **Primeira feature:** com o PRD aprovado, peça ao agente a skill `feature-delivery`.

## Origem

Este template é gerado pelo exportador do kit (modo `--seed`) do repositório de referência [java-ai-engineering-lab](https://github.com/wesleyosantos91/java-ai-engineering-lab). Correções no chassi são feitas lá e chegam aqui por regeneração. O projeto criado pelo `init-project.sh` não depende deste template nem do repositório de referência.

## Licença

[Apache License 2.0](LICENSE). Projetos criados a partir deste template escolhem a própria licença.
EOF
}
if (( seed )); then write_seed_chassis; fi

# 6. Pacote base e classe principal: os do seed, ou os detectados no app de destino (só nos
#    textos da configuração; o app de destino não é tocado). Nome do projeto nos documentos.
rename_package "${STAGE}" "${old_package}" "${new_package}" "${DEST_APP}"
rename_main_class "${STAGE}" "${old_main}" "${new_main}" "${DEST_APP}"
name="${project_name:-[PREENCHER-NEGÓCIO: nome do projeto]}"
rename_literal "${STAGE}" 'Java AI Engineering Lab' "${name}"
slug="$(project_slug "${project_name:-app}")"
# Só a primeira ocorrência: o nome do contêiner, não de outros objetos do arquivo.
sed -i "0,/\"name\": \"[^\"]*\"/ s##\"name\": \"${slug:-app}\"#" "${STAGE}/.devcontainer/devcontainer.json"

# 7. AGENTS.md com as seções do projeto prontas: propósito (negócio), stack detectada no app
#    (engenharia só completa o que não dá para detectar) e scripts que existem no destino.
tools='`check-config.sh`, `sync-skills.sh`, `list-pending.sh`, hooks; `check-prd.sh`'
(( ! seed )) || tools='`check-config.sh`, `sync-skills.sh`, `list-pending.sh`, `init-project.sh`, hooks; `check-prd.sh`'
purpose='Propósito: [PREENCHER-NEGÓCIO: o que o sistema faz e para quem, em uma frase]. Requisitos: [PRD](docs/product/prd.md).'
stack='' persistence=''
if (( ! seed )); then
  starters=''
  [[ ! -f "${dest_pom:-}" ]] || starters="$(sed -n 's#.*<artifactId>spring-boot-starter-\([a-z-]*\)</artifactId>.*#\1#p' "${dest_pom}" |
    grep -v -e '-test$' -e '^parent$' | sort -u | paste -sd, - | sed 's/,/, /g' || true)"
  if [[ -n "${java_version}" && -n "${boot_version}" ]]; then
    stack="- Java ${java_version}, Spring Boot ${boot_version}, Maven via Wrapper em \`app/\` (detectado em \`app/pom.xml\`; starters: ${starters:-nenhum})."
  else
    stack='- [PREENCHER-ENGENHARIA: Java, Spring Boot e build do app (app/pom.xml não encontrado na exportação)].'
  fi
  persistence='- Persistência e integração: [PREENCHER-ENGENHARIA: banco, migrações e testes de integração; os ADRs propostos sugerem Spring JDBC, PostgreSQL, Flyway e Testcontainers].'
fi
awk -v tools="${tools}" -v purpose="${purpose}" -v stack="${stack}" -v persistence="${persistence}" '
  /^\[PREENCHER: propósito do projeto\]\.?$/ { print purpose; next }
  stack != "" && /^- Java [0-9]+, Spring Boot / { print stack; next }
  persistence != "" && /^- Spring JDBC com SQL explícito/ { print persistence; next }
  /^\| `agents\/`, `product\/` \|/ { print "| `agents/`, `product/` | " tools " |"; next }
  { print }' "${STAGE}/AGENTS.md" > "${STAGE}/AGENTS.md.tmp" && mv "${STAGE}/AGENTS.md.tmp" "${STAGE}/AGENTS.md"

# 7b. Guia de quality gates com os blocos prontos para este projeto: extraídos do pom e dos
#     testes de infraestrutura deste repositório, com o pacote e a classe do projeto.
write_gate_blocks() {
  local guide="${STAGE}/docs/how-to/enable-quality-gates.md" pom="${APP_ROOT}/pom.xml"
  local test_root="${APP_ROOT}/src/test/java/${old_path}" new_path="${new_package//.//}"
  local deps='archunit|junit-platform-launcher|spring-boot-testcontainers|testcontainers-junit-jupiter|testcontainers-postgresql'
  adapt() { sed -e "s#${old_package//./\\.}#${new_package}#g" -e "s#${old_path}#${new_path}#g" -e "s#${old_main}#${new_main}#g"; }
  code() { printf '\n```%s\n' "$1"; cat; printf '```\n'; }
  {
    printf '\n## Blocos prontos para este projeto\n\n'
    printf 'Gerados para o pacote `%s` e a classe `%s`. Copie cada bloco para o lugar indicado e ajuste só o que o projeto não usar.\n' "${new_package}" "${new_main}"
    printf '\n### 1. `app/pom.xml`: propriedades (dentro de `<properties>`)\n'
    awk '/<properties>/ { on = 1; next } /<\/properties>/ { on = 0 } on && !/<java.version>/' "${pom}" | adapt | code xml
    printf '\n### 2. `app/pom.xml`: dependências de teste (dentro de `<dependencies>`)\n\nSe o app não usa banco, omita as três dependências de Testcontainers.\n'
    awk -v deps="^(${deps})$" '
      /<dependency>/ { block = ""; on = 1 }
      on { block = block $0 "\n" }
      on && /<artifactId>/ { id = $0; gsub(/.*<artifactId>|<\/artifactId>.*/, "", id) }
      /<\/dependency>/ && on { if (id ~ deps) printf "%s", block; on = 0 }' "${pom}" | code xml
    printf '\n### 3. `app/pom.xml`: plugins (dentro de `<build><plugins>`)\n'
    awk '
      /<plugin>/ && depth == 0 { block = ""; on = 1 }
      on { block = block $0 "\n" }
      on && /<artifactId>spring-boot-maven-plugin<\/artifactId>/ { skip = 1 }
      /<plugin>/ { depth++ } /<\/plugin>/ { depth-- }
      on && depth == 0 { if (!skip) printf "%s", block; on = 0; skip = 0 }' "${pom}" | adapt | code xml
    printf '\n### 4. Classes de teste em `app/src/test/java/%s/`\n' "${new_path}"
    local file
    for file in architecture/ArchitectureTest.java TestcontainersConfiguration.java "${old_main}IT.java" "Test${old_main}.java"; do
      [[ -f "${test_root}/${file}" ]] || continue
      printf '\n`%s`:\n' "$(adapt <<<"${file}")"
      adapt < "${test_root}/${file}" | code java
    done
    printf '\nSem banco, troque `%sIT` por um teste de contexto sem Testcontainers e não crie `TestcontainersConfiguration` nem `Test%s`:\n' "${new_main}" "${new_main}"
    printf 'package %s;\n\nimport org.junit.jupiter.api.Test;\nimport org.springframework.boot.test.context.SpringBootTest;\n\n@SpringBootTest\nclass %sIT {\n\n\t@Test\n\tvoid contextLoads() {\n\t}\n\n}\n' \
      "${new_package}" "${new_main}" | code java
    printf '\n### 5. Ativar\n\nCom os blocos aplicados e `bash scripts/verify.sh` verde, troque `QUALITY_GATES=optional` por `QUALITY_GATES=required` no `.harness`.\n'
  } >> "${guide}"
}
write_gate_blocks

# 8. .harness: projeto Maven em app/; gates obrigatórios no seed, opcionais num projeto existente
#    até o pom do app ser configurado.
gates=optional
(( ! seed )) || gates=required
cat > "${STAGE}/.harness" <<EOF
# Configuração do harness (scripts/lib/app.sh); chave=valor, sem execução de código.
# APP_DIR: projeto Maven, sempre app/ (docs/architecture/repository-layout.md).
# QUALITY_GATES: optional = gate não configurado em app/pom.xml é SKIP; required = FAIL.
#   Para ativar, veja docs/how-to/enable-quality-gates.md.
# REPOSITORY_ROLE: project exige APP_DIR=app (verificado por scripts/agents/check-config.sh).
APP_DIR=${DEST_APP}
QUALITY_GATES=${gates}
REPOSITORY_ROLE=project
EOF

if [[ -e "${DEST}/README.md" ]]; then
  # O README do destino é mantido; a verificação abaixo usa o estado final real.
  cp -p "${DEST}/README.md" "${STAGE}/README.md"
elif [[ ! -e "${STAGE}/README.md" ]]; then
  write_project_readme "${STAGE}/README.md" "${name}"
fi

# 9. Fora do seed, o kit só pode conter configuração: nenhum arquivo sob app/, infra/, tests/
#    ou .github/.
if (( ! seed )); then
  forbidden="$(cd "${STAGE}" && find "${DEST_APP}" infra tests .github -type f 2>/dev/null | head -n 5 || true)"
  if [[ -n "${forbidden}" ]]; then
    printf '%s\n' "${forbidden}" >&2
    echo "[FAIL] O kit só de configuração não pode gravar em ${DEST_APP}/, infra/, tests/ ou .github/." >&2
    exit 1
  fi
fi

# 10. Stubs do Claude Code e verificação do kit antes de tocar o destino. O diretório do app
#     existe na área temporária só para a validação do .harness (diretórios vazios não são copiados).
bash "${STAGE}/scripts/agents/sync-skills.sh" >/dev/null
mkdir -p "${STAGE}/${DEST_APP}"
if ! check_output="$(cd "${STAGE}" && bash scripts/agents/check-config.sh 2>&1)"; then
  printf '%s\n' "${check_output}" >&2
  echo "[FAIL] O kit gerado não passou em agents/check-config.sh; destino não alterado." >&2
  exit 1
fi

# 11. Cópia para o destino sem sobrescrever: conflitos viram <arquivo>.kit.
mkdir -p "${DEST}"
conflicts=() copied=0
while IFS= read -r -d '' file; do
  rel="${file#"${STAGE}"/}"
  target="${DEST}/${rel}"
  mkdir -p "$(dirname -- "${target}")"
  if [[ -e "${target}" ]]; then
    if ! cmp -s "${file}" "${target}"; then
      cp -p "${file}" "${target}.kit"
      conflicts+=("${rel}")
    fi
  else
    cp -p "${file}" "${target}"
    copied=$((copied + 1))
  fi
done < <(find "${STAGE}" -type f -print0)

echo "[PASS] Kit exportado para ${DEST}: ${copied} arquivo(s) novo(s); check-config aprovado no kit."
if (( ${#conflicts[@]} > 0 )); then
  echo "[AVISO] ${#conflicts[@]} arquivo(s) já existiam; a versão do kit está em <arquivo>.kit para mesclar:"
  printf '  - %s\n' "${conflicts[@]}"
fi
if (( seed )); then
  echo "[INFO] Seed gerado. Antes de publicar: git init, bash scripts/git/install-hooks.sh e bash scripts/verify.sh no destino."
  echo "[INFO] Projetos criados a partir dele começam por: bash scripts/agents/init-project.sh (ver README.md do seed)."
  exit 0
fi
echo "[INFO] Projeto em ${DEST_APP}/: $( [[ -f "${DEST}/${DEST_APP}/pom.xml" ]] && echo "pom.xml encontrado" || echo "pom.xml AUSENTE (o harness exige ${DEST_APP}/pom.xml)" ); classe ${detected_main:-não detectada} em ${detected_package:-pacote não detectado}; Java ${java_version:-?}; Spring Boot ${boot_version:-?}."
echo "[INFO] Nada foi gravado em ${DEST_APP}/, infra/, tests/ nem .github/ (gerido por DevOps)."
echo "[INFO] Próximos passos no projeto (seções prontas; só os campos [PREENCHER-...] ficam para preencher):"
[[ -n "${detected_package}" ]] || echo "  - Pacote base não detectado; os textos usam ${new_package}: ajuste skills e docs."
echo "  - Negócio: docs/product/prd.md (bash scripts/product/check-prd.sh), propósito no AGENTS.md §1 e visão geral no README.md."
echo "  - Engenharia: seção \"Revisão neste projeto\" dos ADRs 0001 a 0003, AGENTS.md §2 (persistência) e licença."
echo "  - Quality gates: blocos prontos no fim de docs/how-to/enable-quality-gates.md; depois QUALITY_GATES=required no .harness."
echo "  - Harness: git init (se preciso), bash scripts/git/install-hooks.sh e bash scripts/verify.sh."
pending="$( (cd "${DEST}" && bash scripts/agents/list-pending.sh) | grep -E '^  [^ ]' || true)"
[[ -z "${pending}" ]] || { echo "  - Campos por responsável (lista completa: bash scripts/agents/list-pending.sh):"; sed 's/^/  /' <<<"${pending}"; }
