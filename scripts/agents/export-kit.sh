#!/usr/bin/env bash
set -Eeuo pipefail

# Exporta o kit de configuração AI-First (agentes, harness, documentação de engenharia e
# governança) para outro repositório. Conteúdo específico deste produto (código, PRD, features,
# ADR-0004, aprendizados registrados) fica de fora. Guia: docs/how-to/adopt-in-new-repository.md.
#
# Uso: bash scripts/agents/export-kit.sh <destino> [--base-package <pacote>] [--main-class <Classe>]
#                                                 [--project-name <nome>]
#
# - Arquivos que já existem no destino nunca são sobrescritos: a versão do kit é gravada como
#   <arquivo>.kit para mesclagem manual.
# - Marcadores nos Markdown (<!-- kit:omit-line -->, <!-- kit:replace-line: TEXTO -->,
#   <!-- kit:omit-start --> ... <!-- kit:omit-end -->) removem ou substituem trechos do projeto.
# Retornos: 0 = kit exportado e verificado no destino; 1 = erro (destino intacto).

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
source "${SCRIPT_DIR}/../lib/pom.sh"

usage() {
  echo "Uso: bash scripts/agents/export-kit.sh <destino> [--base-package <pacote>] [--main-class <Classe>] [--project-name <nome>]" >&2
  exit 1
}

dest='' new_package='' new_main='' project_name=''
while (( $# )); do
  case "$1" in
    --base-package) [[ -n "${2:-}" ]] || usage; new_package="$2"; shift 2 ;;
    --main-class) [[ -n "${2:-}" ]] || usage; new_main="$2"; shift 2 ;;
    --project-name) [[ -n "${2:-}" ]] || usage; project_name="$2"; shift 2 ;;
    -h|--help) usage ;;
    -*) echo "[FAIL] Opção desconhecida: $1" >&2; usage ;;
    *) [[ -z "${dest}" ]] || usage; dest="$1"; shift ;;
  esac
done
[[ -n "${dest}" ]] || usage
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

# 5. Pacote base, classe principal e nome do projeto (opcionais).
text_files() { grep -rlI --exclude-dir=.git "$1" "${STAGE}" || true; }
if [[ -n "${new_package}" && "${new_package}" != "${old_package}" ]]; then
  new_path="${new_package//.//}"
  while IFS= read -r file; do [[ -n "${file}" ]] && sed -i "s#${old_package//./\\.}#${new_package}#g" "${file}"; done < <(text_files "${old_package}")
  while IFS= read -r file; do [[ -n "${file}" ]] && sed -i "s#${old_path}#${new_path}#g" "${file}"; done < <(text_files "${old_path}")
  mkdir -p "${STAGE}/src/test/java/${new_path}"
  cp -R "${STAGE}/src/test/java/${old_path}/." "${STAGE}/src/test/java/${new_path}/"
  rm -rf "${STAGE}/src/test/java/${old_path%%/*}"
  [[ -d "${STAGE}/src/test/java/${new_path}" ]] || { echo "[FAIL] Falha ao mover o pacote de testes." >&2; exit 1; }
fi
if [[ -n "${new_main}" && "${new_main}" != "${old_main}" ]]; then
  while IFS= read -r file; do [[ -n "${file}" ]] && sed -i "s#${old_main}#${new_main}#g" "${file}"; done < <(text_files "${old_main}")
  while IFS= read -r -d '' file; do
    mv "${file}" "${file//${old_main}/${new_main}}"
  done < <(find "${STAGE}/src" -type f -name "*${old_main}*" -print0)
fi
name="${project_name:-[PREENCHER: nome do projeto]}"
while IFS= read -r file; do [[ -n "${file}" ]] && sed -i "s#Java AI Engineering Lab#${name}#g" "${file}"; done < <(text_files 'Java AI Engineering Lab')
# Nome do devcontainer: slug do projeto, se informado.
slug="$(printf '%s' "${project_name:-app}" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
sed -i "s#\"name\": \"java-ai-engineering-lab\"#\"name\": \"${slug:-app}\"#" "${STAGE}/.devcontainer/devcontainer.json"

if [[ -e "${DEST}/README.md" ]]; then
  # O README do destino é mantido; a verificação abaixo usa o estado final real.
  cp -p "${DEST}/README.md" "${STAGE}/README.md"
else
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
