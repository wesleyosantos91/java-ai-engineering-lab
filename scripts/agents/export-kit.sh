#!/usr/bin/env bash
set -Eeuo pipefail

# Kit AI-First: monta a configuração reutilizável deste repositório (instruções e skills dos agentes,
# harness, documentação de engenharia, PRD guiado, ADRs propostos) e a aplica num monorepo existente
# ou grava o instalador público (seed). Guia: docs/how-to/adopt-in-new-repository.md.
#
# Uso: bash scripts/agents/export-kit.sh <diretório do projeto>   aplica no projeto (app/ existente)
#      bash scripts/agents/export-kit.sh --seed <diretório>       grava o instalador (seed)
#
# O kit montado tem a forma do seed:
#   install.sh     instalador: bash install.sh <diretório do projeto>
#   lib/           biblioteca do instalador
#   payload/       configuração que vai para a raiz do projeto, com marcadores neutros
#   templates/     pom e classes de teste de referência para os blocos de quality gates
# A aplicação é sempre feita pelo instalador: só configuração na raiz, nada em app/, infra/,
# tests/, .github/ nem no README.md do projeto (docs/architecture/repository-layout.md).
# Marcadores nos Markdown (<!-- kit:omit-line -->, <!-- kit:replace-line: TEXTO -->,
# <!-- kit:omit-start --> ... <!-- kit:omit-end -->) removem ou substituem trechos deste produto.
# Retornos: 0 = kit aplicado (ou seed gravado) e verificado; 1 = erro (destino intacto).

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
source "${SCRIPT_DIR}/../lib/app.sh" || exit 1
source "${SCRIPT_DIR}/../lib/pom.sh"
source "${SCRIPT_DIR}/kit/rename.sh"

# Marcadores neutros do payload; o instalador os troca pelos valores detectados no projeto.
KIT_PACKAGE=com.example.kitapp
KIT_MAIN=KitMainApplication
KIT_NAME='@@PROJECT_NAME@@'
KIT_SLUG='@@PROJECT_SLUG@@'

usage() {
  echo "Uso: bash scripts/agents/export-kit.sh <diretório do projeto>" >&2
  echo "     bash scripts/agents/export-kit.sh --seed <diretório>" >&2
  exit 1
}
seed=0
case "${1:-}" in
  --seed) seed=1; shift ;;
  -h|--help|'') usage ;;
  -*) echo "[FAIL] Opção desconhecida: $1" >&2; usage ;;
esac
(( $# == 1 )) || usage
[[ "$1" != -* ]] || usage

# Origem: pacote, caminho e classe principal declarados no pom do app deste repositório.
old_package="$(pom_property app.basePackage)" || exit 1
old_path="$(pom_property app.basePath)" || exit 1
old_main="$(pom_property app.mainClass)" || exit 1

# O destino não pode ser este repositório nem ficar dentro dele (exceto em target/, usado pelos
# testes do harness).
DEST="$(realpath -m -- "$1")"
[[ ! -e "${DEST}" || -d "${DEST}" ]] || { echo "[FAIL] Destino existe e não é diretório: ${DEST}" >&2; exit 1; }
case "${DEST}/" in
  "${ROOT_DIR}/target/"*) ;;
  "${ROOT_DIR}/"*) echo "[FAIL] O destino não pode estar dentro deste repositório: ${DEST}" >&2; exit 1 ;;
esac
if (( seed )) && [[ -e "${DEST}" ]] && [[ -n "$(find "${DEST}" -mindepth 1 -maxdepth 1 ! -name .git -print -quit)" ]]; then
  echo "[FAIL] --seed exige um diretório vazio (ou só com .git): ${DEST}" >&2; exit 1
fi
if (( ! seed )) && [[ ! -d "${DEST}" ]]; then
  echo "[FAIL] Diretório do projeto não encontrado: ${DEST}" >&2; exit 1
fi

KIT="$(mktemp -d)"
trap 'rm -rf "${KIT}"' EXIT
STAGE="${KIT}/payload"
mkdir -p "${STAGE}" "${KIT}/lib" "${KIT}/templates/test/architecture"

# 1. Configuração AI-First: somente arquivos versionáveis (rastreados ou novos não ignorados).
#    Sem .github/ (DevOps), sem código do app, sem README e sem artefatos deste produto.
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
# As ferramentas do kit ficam neste repositório e no seed: o projeto não depende delas.
rm -rf "${STAGE}/scripts/agents/export-kit.sh" "${STAGE}/scripts/agents/kit" "${STAGE}/scripts/harness-tests/export-kit.sh"

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

# 5. AGENTS.md: propósito pronto para o negócio e tabela de scripts do projeto (sem o kit).
awk '
  /^\[PREENCHER: propósito do projeto\]\.?$/ {
    print "Propósito: [PREENCHER-NEGÓCIO: o que o sistema faz e para quem, em uma frase]. Requisitos: [PRD](docs/product/prd.md)."; next }
  /^\| `agents\/`, `product\/` \|/ { print "| `agents/`, `product/` | `check-config.sh`, `sync-skills.sh`, `list-pending.sh`, hooks; `check-prd.sh` |"; next }
  { print }' "${STAGE}/AGENTS.md" > "${STAGE}/AGENTS.md.tmp" && mv "${STAGE}/AGENTS.md.tmp" "${STAGE}/AGENTS.md"

# 6. Referências deste produto viram marcadores neutros (o instalador aplica os do projeto).
rename_package "${STAGE}" "${old_package}" "${KIT_PACKAGE}"
rename_literal "${STAGE}" "${old_main}" "${KIT_MAIN}"
rename_literal "${STAGE}" 'Java AI Engineering Lab' "${KIT_NAME}"
sed -i "0,/\"name\": \"[^\"]*\"/ s##\"name\": \"${KIT_SLUG}\"#" "${STAGE}/.devcontainer/devcontainer.json"

# 7. Templates dos blocos de quality gates: pom e testes de infraestrutura deste repositório.
cp "${APP_ROOT}/pom.xml" "${KIT}/templates/pom.xml"
test_root="${APP_ROOT}/src/test/java/${old_path}"
cp "${test_root}/architecture/ArchitectureTest.java" "${KIT}/templates/test/architecture/"
cp "${test_root}/TestcontainersConfiguration.java" "${KIT}/templates/test/"
cp "${test_root}/${old_main}IT.java" "${KIT}/templates/test/${KIT_MAIN}IT.java"
cp "${test_root}/Test${old_main}.java" "${KIT}/templates/test/Test${KIT_MAIN}.java"
rename_literal "${KIT}/templates" "${old_package}" "${KIT_PACKAGE}"
rename_literal "${KIT}/templates" "${old_path}" "${KIT_PACKAGE//.//}"
rename_literal "${KIT}/templates" "${old_main}" "${KIT_MAIN}"

# 8. Instalador.
cp "${SCRIPT_DIR}/kit/install.sh" "${KIT}/install.sh"
cp "${SCRIPT_DIR}/kit/rename.sh" "${KIT}/lib/rename.sh"

# Nenhum resíduo deste produto no kit (o README do seed, escrito abaixo, cita a origem).
residue="$(grep -rlIE "${old_package//./\\.}|${old_path}|${old_main}|Java AI Engineering Lab" "${KIT}" || true)"
if [[ -n "${residue}" ]]; then
  printf '%s\n' "${residue}" >&2
  echo "[FAIL] Kit com referências deste produto; destino não alterado." >&2; exit 1
fi

if (( ! seed )); then
  bash "${KIT}/install.sh" "${DEST}"
  exit
fi

# 9. Seed: o instalador público, verificado num projeto de exemplo antes de ser gravado.
probe="$(mktemp -d)"
trap 'rm -rf "${KIT}" "${probe}"' EXIT
mkdir -p "${probe}/app/src/main/java/com/acme/probe"
printf '<project>\n\t<parent>\n\t\t<version>4.1.2</version>\n\t</parent>\n\t<artifactId>probe</artifactId>\n\t<properties><java.version>27</java.version></properties>\n</project>\n' > "${probe}/app/pom.xml"
printf 'package com.acme.probe;\n\n@SpringBootApplication\npublic class ProbeApplication {}\n' > "${probe}/app/src/main/java/com/acme/probe/ProbeApplication.java"
if ! probe_output="$(bash "${KIT}/install.sh" "${probe}" 2>&1)"; then
  printf '%s\n' "${probe_output}" >&2
  echo "[FAIL] O instalador falhou no projeto de exemplo; seed não gravado." >&2; exit 1
fi
rm -rf "${probe}"
[[ -f "${ROOT_DIR}/LICENSE" && -f "${ROOT_DIR}/NOTICE" ]] ||
  { echo "[FAIL] --seed exige LICENSE e NOTICE na raiz deste repositório." >&2; exit 1; }
cp "${ROOT_DIR}/LICENSE" "${KIT}/LICENSE"
sed '1s/.*/Java AI-First Seed/' "${ROOT_DIR}/NOTICE" > "${KIT}/NOTICE"
# Scripts com LF em qualquer sistema (o instalador roda no Git Bash do Windows).
printf '* text=auto eol=lf\n*.cmd text eol=crlf\n' > "${KIT}/.gitattributes"
cat > "${KIT}/README.md" <<'EOF'
# Java AI-First Seed

Instalador da configuração AI-First para monorepos Java com agentes de IA (Codex, Claude Code, Devin): instruções e skills dos agentes, harness de verificação, quality gates, PRD guiado e ADRs propostos.

Ele **não cria projeto**. Você aponta o diretório de um monorepo que já existe, com o projeto Maven em `app/`, e o instalador adiciona só a configuração na raiz.

## Uso

```bash
git clone https://github.com/wesleyosantos91/java-ai-first-seed.git
bash java-ai-first-seed/install.sh /caminho/do/monorepo
```

O instalador:

- **detecta** em `app/` (só leitura) a classe `@SpringBootApplication`, o pacote, o Java, o Spring Boot, os starters e o nome do projeto;
- **grava só configuração na raiz:** `AGENTS.md`, `CLAUDE.md`, `.agents/`, `.claude/`, `.codex/`, `docs/`, `scripts/`, `.harness` e arquivos de editor e Git;
- **não altera** `app/`, `infra/`, `tests/`, `.github/` nem o `README.md` do projeto. Se um arquivo de configuração já existe e é diferente, a versão do kit fica ao lado como `<arquivo>.kit`;
- verifica tudo numa área temporária antes de gravar. Se algo falhar, o projeto não é alterado.

Nada deste repositório é copiado para o projeto: ele continua sem depender do seed.

## Estrutura esperada do projeto

```text
<monorepo>/
├── app/        projeto Maven (app/pom.xml), obrigatório
├── infra/      infraestrutura (por exemplo, Terraform), opcional
├── tests/      testes fora do app, opcional
└── .github/    CI do time de DevOps, opcional
```

## Depois de instalar

| Quem | O quê |
|---|---|
| Negócio | PRD em `docs/product/prd.md` (cada seção diz quem preenche) e propósito no `AGENTS.md` §1 |
| Engenharia | Seção "Revisão neste projeto" dos ADRs 0001 a 0003, persistência no `AGENTS.md` §2 e licença no `CONTRIBUTING.md` |
| Engenharia | Quality gates: blocos de pom e testes prontos no fim de `docs/how-to/enable-quality-gates.md` |

```bash
bash scripts/agents/list-pending.sh   # o que falta preencher, por responsável
bash scripts/git/install-hooks.sh     # hooks de commit (exige repositório Git)
bash scripts/verify.sh                # agentes, build e testes do app/
```

Até os quality gates serem configurados no `app/pom.xml`, eles aparecem como SKIP com o motivo, e o `verify.sh` termina PARCIAL. É o esperado.

## Origem

Gerado pelo exportador do kit (`--seed`) do repositório de referência [java-ai-engineering-lab](https://github.com/wesleyosantos91/java-ai-engineering-lab). Correções são feitas lá e chegam aqui por regeneração.

## Licença

[Apache License 2.0](LICENSE).
EOF
mkdir -p "${DEST}"
cp -R "${KIT}/." "${DEST}/"
echo "[PASS] Seed (instalador) gravado em ${DEST}; instalação verificada num projeto de exemplo."
echo "[INFO] Uso: bash ${DEST}/install.sh <diretório do projeto>"
