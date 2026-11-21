#!/usr/bin/env bash
set -Eeuo pipefail

# Autoteste do instalador do kit AI-First: instala num monorepo temporário (app/ Maven, infra/,
# tests/, .github/ e README.md) e comprova que só a configuração foi gravada, que ela passa no
# check-config e no harness do projeto (Maven simulado) e que a reinstalação preserva o .harness.
# Não usa rede, Maven nem Docker; não altera este diretório.
#
# Uso: bash selftest.sh
# Retornos: 0 = PASS; 1 = FAIL.

KIT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT
fail() { echo "[FAIL] selftest: $*" >&2; exit 1; }
pass() { echo "[PASS] selftest: $*"; }
project_hash() { (cd "$1" && find app infra tests .github README.md -type f -print0 | sort -z | xargs -0 sha1sum | sha1sum); }
kit_hash() { (cd "${KIT_DIR}" && find . -type f ! -path './.git/*' -print0 | sort -z | xargs -0 sha1sum | sha1sum); }

dest="${WORK}/monorepo"
mkdir -p "${dest}/app/src/main/java/com/acme/demo" "${dest}/infra/terraform" "${dest}/tests" "${dest}/.github/workflows"
printf '<project>\n\t<parent>\n\t\t<version>4.2.0</version>\n\t</parent>\n\t<artifactId>demo</artifactId>\n\t<properties><java.version>17</java.version></properties>\n</project>\n' > "${dest}/app/pom.xml"
printf '#!/usr/bin/env bash\necho "mvn $*"\n' > "${dest}/app/mvnw"
printf 'package com.acme.demo;\n\n@SpringBootApplication\npublic class DemoApplication {}\n' > "${dest}/app/src/main/java/com/acme/demo/DemoApplication.java"
printf 'terraform {}\n' > "${dest}/infra/terraform/main.tf"
printf 'smoke\n' > "${dest}/tests/README.txt"
printf 'name: ci\n' > "${dest}/.github/workflows/ci.yml"
printf '# Demo\n' > "${dest}/README.md"
before="$(project_hash "${dest}")" kit_before="$(kit_hash)"

bash "${KIT_DIR}/install.sh" "${dest}" > "${WORK}/install.log" 2>&1 || { cat "${WORK}/install.log" >&2; fail "instalação falhou"; }
pass "instalação concluída"
[[ "$(project_hash "${dest}")" == "${before}" ]] || fail "app/, infra/, tests/, .github/ ou README.md foram alterados"
pass "app/, infra/, tests/, .github/ e README.md intactos"
for path in AGENTS.md CLAUDE.md .harness scripts/verify.sh docs/product/prd.md .claude/skills/feature-delivery/SKILL.md; do
  [[ -e "${dest}/${path}" ]] || fail "ausente no projeto: ${path}"
done
for path in install.sh selftest.sh payload templates lib VERSION; do
  [[ ! -e "${dest}/${path}" ]] || fail "arquivo do instalador copiado para o projeto: ${path}"
done
grep -qx "KIT_VERSION=$(head -n 1 "${KIT_DIR}/VERSION")" "${dest}/.harness" || fail "KIT_VERSION ausente no .harness"
grep -q '"version": "17"' "${dest}/.devcontainer/devcontainer.json" || fail "devcontainer sem o Java do app"
pass "configuração completa, sem arquivos do instalador"

(cd "${dest}" && git init -q && git add -A) || fail "git init"
(cd "${dest}" && bash scripts/agents/check-config.sh > "${WORK}/check.log" 2>&1) || { cat "${WORK}/check.log" >&2; fail "check-config"; }
pass "check-config aprovado no projeto"
(cd "${dest}" && bash scripts/harness-tests/harness.sh > "${WORK}/harness.log" 2>&1) || { tail -20 "${WORK}/harness.log" >&2; fail "harness do projeto"; }
pass "contratos do harness aprovados no projeto"

# Reinstalação com gates já ativados pelo projeto: o valor é preservado.
sed -i 's/^QUALITY_GATES=optional$/QUALITY_GATES=required/' "${dest}/.harness"
bash "${KIT_DIR}/install.sh" "${dest}" > "${WORK}/reinstall.log" 2>&1 || { cat "${WORK}/reinstall.log" >&2; fail "reinstalação falhou"; }
grep -qx 'QUALITY_GATES=required' "${dest}/.harness" || fail "reinstalação não preservou QUALITY_GATES"
[[ ! -e "${dest}/.harness.kit" ]] || fail "reinstalação gerou .harness.kit"
[[ "$(project_hash "${dest}")" == "${before}" ]] || fail "reinstalação alterou arquivos do projeto"
pass "reinstalação preserva QUALITY_GATES e não toca o projeto"

# Atualização: arquivo idêntico ao que o kit instalou é atualizado no lugar (simulado como instalado
# por uma versão anterior: conteúdo e registro no .kit-manifest trocados juntos); arquivo alterado
# pelo projeto não é sobrescrito e recebe a versão nova em .kit.
[[ -s "${dest}/.kit-manifest" ]] || fail ".kit-manifest ausente"
printf '# versão anterior\n' > "${dest}/CLAUDE.md"
old_hash="$(sha1sum < "${dest}/CLAUDE.md" | cut -d' ' -f1)"
sed -i "s#^[0-9a-f]* CLAUDE.md\$#${old_hash} CLAUDE.md#" "${dest}/.kit-manifest"
printf '\nAjuste do projeto.\n' >> "${dest}/SECURITY.md"
bash "${KIT_DIR}/install.sh" "${dest}" > "${WORK}/upgrade.log" 2>&1 || { cat "${WORK}/upgrade.log" >&2; fail "atualização falhou"; }
grep -q '^@AGENTS.md' "${dest}/CLAUDE.md" || fail "arquivo não alterado pelo projeto não foi atualizado"
[[ ! -e "${dest}/CLAUDE.md.kit" ]] || fail "arquivo não alterado pelo projeto virou .kit"
grep -q 'Ajuste do projeto.' "${dest}/SECURITY.md" || fail "arquivo alterado pelo projeto foi sobrescrito"
[[ -f "${dest}/SECURITY.md.kit" ]] || fail "arquivo alterado pelo projeto sem .kit"
grep -q '1 atualizado(s)' "${WORK}/upgrade.log" || { cat "${WORK}/upgrade.log" >&2; fail "relatório sem a contagem de atualizados"; }
pass "atualização: arquivo do kit atualizado no lugar; arquivo do projeto preservado com .kit"

[[ "$(kit_hash)" == "${kit_before}" ]] || fail "o kit foi alterado pela instalação"
echo "[PASS] Autoteste do instalador concluído (kit $(head -n 1 "${KIT_DIR}/VERSION"))."
