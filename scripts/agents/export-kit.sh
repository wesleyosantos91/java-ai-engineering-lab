#!/usr/bin/env bash
set -Eeuo pipefail

# Exporta o kit de configuração AI-First (agentes, harness, documentação de engenharia e
# governança) para outro repositório. Conteúdo específico deste produto (código, PRD, features,
# ADR-0004, aprendizados registrados) fica de fora. Guia: docs/how-to/adopt-in-new-repository.md.
#
# Uso: bash scripts/agents/export-kit.sh <destino> [--base-package <pacote>] [--main-class <Classe>]
#                                                 [--project-name <nome>]
#      bash scripts/agents/export-kit.sh <destino> --seed
#
# - --seed gera o chassi público (GitHub Template): pacote com.example.seed, classe SeedApplication,
#   aplicação mínima compilável, LICENSE/NOTICE e README de uso; scripts/agents/init-project.sh
#   troca esses nomes no repositório criado a partir do template.
# - Arquivos que já existem no destino nunca são sobrescritos: a versão do kit é gravada como
#   <arquivo>.kit para mesclagem manual.
# - Marcadores nos Markdown (<!-- kit:omit-line -->, <!-- kit:replace-line: TEXTO -->,
#   <!-- kit:omit-start --> ... <!-- kit:omit-end -->) removem ou substituem trechos do projeto.
# Retornos: 0 = kit exportado e verificado no destino; 1 = erro (destino intacto).

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
source "${SCRIPT_DIR}/../lib/pom.sh"
source "${SCRIPT_DIR}/../lib/rename.sh"

# Nomes do seed: init-project.sh os procura para renomear (não altere um sem o outro).
SEED_PACKAGE=com.example.seed
SEED_MAIN=SeedApplication
SEED_NAME='Java AI-First Seed'
SEED_SLUG=java-ai-first-seed

usage() {
  echo "Uso: bash scripts/agents/export-kit.sh <destino> [--base-package <pacote>] [--main-class <Classe>] [--project-name <nome>]" >&2
  echo "     bash scripts/agents/export-kit.sh <destino> --seed" >&2
  exit 1
}

dest='' new_package='' new_main='' project_name='' seed=0
while (( $# )); do
  case "$1" in
    --base-package) [[ -n "${2:-}" ]] || usage; new_package="$2"; shift 2 ;;
    --main-class) [[ -n "${2:-}" ]] || usage; new_main="$2"; shift 2 ;;
    --project-name) [[ -n "${2:-}" ]] || usage; project_name="$2"; shift 2 ;;
    --seed) seed=1; shift ;;
    -h|--help) usage ;;
    -*) echo "[FAIL] Opção desconhecida: $1" >&2; usage ;;
    *) [[ -z "${dest}" ]] || usage; dest="$1"; shift ;;
  esac
done
[[ -n "${dest}" ]] || usage
if (( seed )); then
  [[ -z "${new_package}${new_main}${project_name}" ]] || {
    echo "[FAIL] --seed usa nomes fixos; personalize depois com scripts/agents/init-project.sh." >&2; exit 1; }
  new_package="${SEED_PACKAGE}" new_main="${SEED_MAIN}" project_name="${SEED_NAME}"
fi
if [[ -n "${new_package}" && ! "${new_package}" =~ ^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$ ]]; then
  echo "[FAIL] --base-package inválido: '${new_package}' (ex.: com.acme.orders)." >&2; exit 1
fi
if [[ -n "${new_main}" && ! "${new_main}" =~ ^[A-Z][A-Za-z0-9_]*$ ]]; then
  echo "[FAIL] --main-class inválido: '${new_main}' (ex.: OrdersApplication)." >&2; exit 1
fi

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
mkdir -p "${DEST}"

STAGE="$(mktemp -d)"
trap 'rm -rf "${STAGE}"' EXIT

# Chassi do seed: aplicação mínima compilável, identidade Maven neutra, licença e README de uso.
write_seed_chassis() {
  local main_dir="${STAGE}/src/main/java/${SEED_PACKAGE//.//}" resources="${STAGE}/src/main/resources"
  mkdir -p "${main_dir}" "${resources}/db/migration"
  cat > "${main_dir}/${SEED_MAIN}.java" <<EOF
package ${SEED_PACKAGE};

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class ${SEED_MAIN} {

	public static void main(String[] args) {
		SpringApplication.run(${SEED_MAIN}.class, args);
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
    "${STAGE}/pom.xml"
  [[ -f "${ROOT_DIR}/LICENSE" && -f "${ROOT_DIR}/NOTICE" ]] ||
    { echo "[FAIL] --seed exige LICENSE e NOTICE na raiz do repositório de origem." >&2; exit 1; }
  cp "${ROOT_DIR}/LICENSE" "${STAGE}/LICENSE"
  sed "1s/.*/${SEED_NAME}/" "${ROOT_DIR}/NOTICE" > "${STAGE}/NOTICE"
  cat > "${STAGE}/README.md" <<'EOF'
# Java AI-First Seed

Chassi de contexto para projetos Java desenvolvidos com agentes de IA (Codex, Claude Code, Devin). Não contém regra de negócio: traz as instruções dos agentes, as skills, o harness de verificação, os quality gates, a governança e um PRD guiado para o time de negócio preencher.

## O que vem pronto

| Parte | Onde |
|---|---|
| Instruções e skills dos agentes | [AGENTS.md](AGENTS.md), `.agents/skills/`, adaptadores `CLAUDE.md`, `.claude/`, `.codex/` |
| Harness (build, testes, quality gates, segredos, hooks Git) | `scripts/`, guia em [run-tests.md](docs/how-to/run-tests.md) |
| Aplicação mínima | Spring Boot 4, Java 27, Spring JDBC, PostgreSQL, Flyway, Testcontainers; sem endpoints |
| PRD a preencher | [docs/product/prd.md](docs/product/prd.md) |
| Decisões herdadas (para revisar) | [docs/architecture/adr/](docs/architecture/adr/README.md) |
| Critérios de conclusão | [definition-of-done.md](docs/engineering/definition-of-done.md) |

## Como começar

1. **Criar o repositório:** botão *Use this template* no GitHub e clone do novo repositório.
2. **Dar nome ao projeto** (troca pacote, classe principal, identidade Maven e este README):

   ```bash
   bash scripts/agents/init-project.sh --base-package com.acme.orders \
     --main-class OrdersApplication --project-name "Orders Service"
   ```

3. **Time de negócio: preencher o PRD** em [docs/product/prd.md](docs/product/prd.md). Cada seção diz quem a preenche (`Negócio`, `Engenharia` ou `Ambos`) e se é obrigatória; os campos pendentes aparecem como `[PREENCHER-NEGÓCIO: ...]` e `[PREENCHER-ENGENHARIA: ...]`. Para ver o que falta, por responsável:

   ```bash
   bash scripts/product/check-prd.sh
   ```

   O PRD só pode ser marcado como **Aprovado** sem pendências; a verificação dos agentes falha caso contrário.

4. **Engenharia:** complete as seções técnicas do PRD, ajuste o `AGENTS.md` (§1 propósito, §2 stack), revise os ADRs herdados, `CODEOWNERS`, `OWNER/REPO` nos templates de issue e a licença.
5. **Ativar o harness:**

   ```bash
   bash scripts/git/install-hooks.sh
   bash scripts/setup.sh
   bash scripts/verify.sh
   ```

   Sem código de negócio, unitários, arquitetura e cobertura retornam SKIP e o resultado é PARCIAL. É o esperado até a primeira feature.

6. **Primeira feature:** com o PRD aprovado, peça ao agente a skill `feature-delivery`.

## Origem

Este repositório é gerado por `scripts/agents/export-kit.sh --seed` a partir do repositório de referência [java-ai-engineering-lab](https://github.com/wesleyosantos91/java-ai-engineering-lab). Correções no chassi devem ser feitas lá e regeneradas aqui.

## Licença

[Apache License 2.0](LICENSE). Projetos criados a partir deste template escolhem a própria licença.
EOF
}

# 1. Conteúdo do kit: somente arquivos versionáveis (rastreados ou novos não ignorados).
include=(
  AGENTS.md CLAUDE.md CONTRIBUTING.md SECURITY.md
  .agents .claude/settings.json .codex .devcontainer .github scripts
  .editorconfig .gitattributes .gitignore .gitleaks.toml
  mvnw mvnw.cmd .mvn pom.xml performance/k6/smoke.js
  docs/ai docs/engineering docs/how-to/run-tests.md
  docs/architecture/package-conventions.md docs/architecture/dependency-rules.md
  docs/architecture/adr/README.md docs/architecture/adr/TEMPLATE.md
  docs/architecture/adr/0001-architecture-principles.md
  docs/architecture/adr/0002-multi-provider-agent-context.md
  docs/architecture/adr/0003-test-suites-and-quality-gates.md
  docs/features/README.md docs/features/TEMPLATE.md docs/product/TEMPLATE.md
  "src/test/java/${old_path}/TestcontainersConfiguration.java"
  "src/test/java/${old_path}/${old_main}IT.java"
  "src/test/java/${old_path}/Test${old_main}.java"
  "src/test/java/${old_path}/architecture"
)
(cd "${ROOT_DIR}" && git ls-files -z --cached --others --exclude-standard -- "${include[@]}" |
  tar --null -T - -cf -) | (cd "${STAGE}" && tar -xf -)

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

# 3. ADRs herdados entram como Proposta, para revisão no novo repositório.
inherited='Proposta (herdada do kit de configuração; revise e aceite)'
adr_dir="${STAGE}/docs/architecture/adr"
sed -i "/^## Status$/,/^## / s/^Aceita$/${inherited}/" "${adr_dir}/0001-architecture-principles.md"
sed -i "s/^- \*\*Status:\*\* Proposta$/- **Status:** ${inherited}/; s/^- \*\*Responsável pela decisão:\*\* .*/- **Responsável pela decisão:** [PREENCHER]/" \
  "${adr_dir}"/000[23]-*.md
sed -i -E 's/^(\| \[000[1-3]\]\([^)]*\) \| [^|]* \| )[^|]*( \| )[^|]*( \|)$/\1Proposta (herdada do kit)\2—\3/' "${adr_dir}/README.md"

# 4. PRD inicial a partir do template; governança com placeholders do novo dono.
cp "${STAGE}/docs/product/TEMPLATE.md" "${STAGE}/docs/product/prd.md"
sed -i '/^\* @/ s/.*/# [ADAPTAR: * @owner-ou-time]/' "${STAGE}/.github/CODEOWNERS"
find "${STAGE}/.github" -type f -exec sed -i 's#wesleyosantos91/java-ai-engineering-lab#OWNER/REPO#g' {} +

# 5. Pacote base, classe principal e nome do projeto (opcionais; fixos no modo --seed).
rename_package "${STAGE}" "${old_package}" "${new_package:-${old_package}}"
rename_main_class "${STAGE}" "${old_main}" "${new_main:-${old_main}}"
name="${project_name:-[PREENCHER: nome do projeto]}"
rename_literal "${STAGE}" 'Java AI Engineering Lab' "${name}"
# Nome do devcontainer: slug do projeto, se informado.
slug="$(project_slug "${project_name:-app}")"
# Só a primeira ocorrência: o nome do contêiner, não de outros objetos do arquivo.
sed -i "0,/\"name\": \"[^\"]*\"/ s##\"name\": \"${slug:-app}\"#" "${STAGE}/.devcontainer/devcontainer.json"
if (( seed )); then write_seed_chassis; fi

if [[ -e "${DEST}/README.md" ]]; then
  # O README do destino é mantido; a verificação abaixo usa o estado final real.
  cp -p "${DEST}/README.md" "${STAGE}/README.md"
elif [[ ! -e "${STAGE}/README.md" ]]; then
  printf '# %s\n\n[PREENCHER: o que o projeto faz e como começar.]\n\nInstruções para agentes de IA: [AGENTS.md](AGENTS.md). Como contribuir: [CONTRIBUTING.md](CONTRIBUTING.md).\n' \
    "${name}" > "${STAGE}/README.md"
fi

# 6. Stubs do Claude Code e verificação do kit antes de tocar o destino.
bash "${STAGE}/scripts/agents/sync-skills.sh" >/dev/null
if ! check_output="$(cd "${STAGE}" && bash scripts/agents/check-config.sh 2>&1)"; then
  printf '%s\n' "${check_output}" >&2
  echo "[FAIL] O kit gerado não passou em agents/check-config.sh; destino não alterado." >&2
  exit 1
fi

# 7. Cópia para o destino sem sobrescrever: conflitos viram <arquivo>.kit.
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
echo "[INFO] Checklist de adaptação (guia completo no repositório de origem: docs/how-to/adopt-in-new-repository.md):"
[[ -n "${new_package}" ]] || echo "  - Pacote base mantido (${old_package}); use --base-package ou ajuste pom.xml (app.*) e src/test/java."
echo "  - pom.xml: groupId, artifactId, name, description, licenses e dependências do projeto."
echo "  - AGENTS.md §1 (propósito) e §2 (stack); CLAUDE.md não precisa de ajuste."
echo "  - Revise e aceite os ADRs herdados (0001 a 0003); escreva o PRD em docs/product/prd.md."
echo "  - Licença (LICENSE/NOTICE) e CODEOWNERS; troque OWNER/REPO nos templates de issue."
echo "  - Instale os hooks: bash scripts/git/install-hooks.sh; depois bash scripts/verify.sh."
placeholders="$(grep -rlE '\[(PREENCHER|ADAPTAR)' "${DEST}" --include='*.md' --include='*.yml' --include='CODEOWNERS' 2>/dev/null |
  sed "s#^${DEST}/##" | sort | tr '\n' ' ' || true)"
[[ -z "${placeholders}" ]] || echo "  - Placeholders [PREENCHER]/[ADAPTAR] em: ${placeholders}"
