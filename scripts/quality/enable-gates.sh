#!/usr/bin/env bash
set -Eeuo pipefail

# Aplica no app os blocos prontos de quality gates da seção "Blocos prontos para este projeto" de
# docs/how-to/enable-quality-gates.md (gerada pelo instalador do kit com o pacote do projeto):
# propriedades, dependências de teste e plugins no pom do app, classes de teste e
# QUALITY_GATES=required no .harness. Mudança de build: execute só com autorização.
#
# Uso: bash scripts/quality/enable-gates.sh --dry-run   mostra o que mudaria, sem gravar
#      bash scripts/quality/enable-gates.sh --apply     aplica (exige app/ limpo no Git)
# - Sem banco no app (nenhum starter JDBC/JPA, PostgreSQL ou Flyway), usa o teste de contexto sem
#   Testcontainers e omite as dependências de Testcontainers.
# - Não sobrescreve classes de teste existentes; não renomeia classes *Tests (só avisa).
# Retornos: 0 = aplicado, simulado ou já configurado; 1 = erro (nada gravado).

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd -P)"
source "${SCRIPT_DIR}/../lib/app.sh" || exit 1
source "${SCRIPT_DIR}/../lib/pom.sh"
source "${SCRIPT_DIR}/../lib/lock.sh"

case "${1:-}" in
  --dry-run) apply=0 ;;
  --apply) apply=1 ;;
  *) echo "Uso: bash scripts/quality/enable-gates.sh --dry-run | --apply" >&2; exit 1 ;;
esac
(( $# == 1 )) || { echo "Uso: bash scripts/quality/enable-gates.sh --dry-run | --apply" >&2; exit 1; }
acquire_harness_lock || exit 1
require_maven_project || exit 1
POM="${APP_ROOT}/pom.xml"
GUIDE="${ROOT_DIR}/docs/how-to/enable-quality-gates.md"

if pom_has '<id>coverage-check</id>' && pom_has 'pitest-maven'; then
  echo "[PASS] Quality gates já configurados em ${APP_PREFIX}pom.xml; nada a aplicar."
  exit 0
fi
grep -q '^## Blocos prontos para este projeto' "${GUIDE}" 2>/dev/null || {
  echo "[FAIL] Seção \"Blocos prontos para este projeto\" ausente em docs/how-to/enable-quality-gates.md (gerada pelo instalador do kit)." >&2
  exit 1
}
for tag in '</properties>' '</dependencies>' '</project>'; do
  grep -qF "${tag}" "${POM}" || { echo "[FAIL] ${APP_PREFIX}pom.xml sem ${tag}; adicione a seção vazia e repita." >&2; exit 1; }
done

# 1. Extrai os blocos do guia: 3 blocos XML (propriedades, dependências, plugins), as classes de
#    teste rotuladas (`caminho.java`:) e o teste de contexto sem banco (bloco Java sem rótulo).
BLOCKS="$(mktemp -d)"
trap 'rm -rf "${BLOCKS}"; release_harness_lock' EXIT
awk -v out="${BLOCKS}" '
  /^## Blocos prontos para este projeto/ { on = 1; next }
  !on { next }
  /^`[^`]+\.java`:$/ { label = $0; gsub(/^`|`:$/, "", label); next }
  /^```/ {
    if (inblock) { close(file); inblock = 0; label = ""; next }
    inblock = 1
    if ($0 ~ /xml/) { file = out "/xml-" (++xml); next }
    name = (label != "" ? label : "nodb-it"); gsub(/\//, "__", name)
    file = out "/java-" name
    next
  }
  inblock { print > file }' "${GUIDE}"
for part in xml-1 xml-2 xml-3 java-nodb-it; do
  [[ -s "${BLOCKS}/${part}" ]] || { echo "[FAIL] Bloco ${part} não encontrado no guia." >&2; exit 1; }
done

# 2. Variante com ou sem banco, conforme as dependências do app.
if grep -qE 'spring-boot-starter-(jdbc|data-[a-z-]+)|<artifactId>postgresql</artifactId>|flyway' "${POM}"; then
  database=1
else
  database=0
  awk '
    /<dependency>/ { block = ""; on = 1 }
    on { block = block $0 "\n"; if ($0 ~ /testcontainers/) skip = 1 }
    /<\/dependency>/ && on { if (!skip) printf "%s", block; on = 0; skip = 0 }' "${BLOCKS}/xml-2" > "${BLOCKS}/xml-2.nodb"
  mv "${BLOCKS}/xml-2.nodb" "${BLOCKS}/xml-2"
fi

# 3. Classes de teste a criar (caminhos relativos a app/src/test/java/<pacote>/).
package="$(pom_property app.basePackage 2>/dev/null || true)"
[[ -n "${package}" ]] || package="$(sed -n 's#.*<app.basePackage>\([^<]*\)</app.basePackage>.*#\1#p' "${BLOCKS}/xml-1" | head -n 1)"
main="$(sed -n 's#.*<app.mainClass>\([^<]*\)</app.mainClass>.*#\1#p' "${BLOCKS}/xml-1" | head -n 1)"
[[ -n "${package}" && -n "${main}" ]] || { echo "[FAIL] Pacote ou classe principal não encontrados nos blocos." >&2; exit 1; }
test_dir="${APP_ROOT}/src/test/java/${package//.//}"
declare -A classes=()
classes["architecture/ArchitectureTest.java"]="${BLOCKS}/java-architecture__ArchitectureTest.java"
if (( database )); then
  classes["TestcontainersConfiguration.java"]="${BLOCKS}/java-TestcontainersConfiguration.java"
  classes["${main}IT.java"]="${BLOCKS}/java-${main}IT.java"
  classes["Test${main}.java"]="${BLOCKS}/java-Test${main}.java"
else
  classes["${main}IT.java"]="${BLOCKS}/java-nodb-it"
fi
for rel in "${!classes[@]}"; do
  [[ -s "${classes[${rel}]}" ]] || { echo "[FAIL] Classe ${rel} não encontrada nos blocos do guia." >&2; exit 1; }
  [[ ! -e "${test_dir}/${rel}" ]] || { echo "[FAIL] ${APP_PREFIX}src/test/java/${package//.//}/${rel} já existe; nada foi gravado." >&2; exit 1; }
done

echo "[INFO] Quality gates para ${package}.${main} ($([[ ${database} == 1 ]] && echo 'com banco: Testcontainers' || echo 'sem banco: teste de contexto')):"
echo "  - ${APP_PREFIX}pom.xml: $(wc -l < "${BLOCKS}/xml-1" | tr -d ' ') linha(s) de propriedades, $(grep -c '<dependency>' "${BLOCKS}/xml-2") dependência(s) de teste, $(grep -c '^			<plugin>' "${BLOCKS}/xml-3") plugin(s)"
for rel in $(printf '%s\n' "${!classes[@]}" | sort); do echo "  - criar ${APP_PREFIX}src/test/java/${package//.//}/${rel}"; done
echo "  - .harness: QUALITY_GATES=required"
tests_files="$(find "${APP_ROOT}/src/test/java" -name '*Tests.java' 2>/dev/null | sed "s#^${ROOT_DIR}/##" || true)"
[[ -z "${tests_files}" ]] || { echo "[AVISO] Classes *Tests não executam pela convenção (*Test, *IT); renomeie-as:"; sed 's/^/  - /' <<<"${tests_files}"; }

if (( ! apply )); then
  echo "[PASS] Simulação concluída; nada foi gravado. Aplique com: bash scripts/quality/enable-gates.sh --apply"
  exit 0
fi

# 4. Aplicação: só com app/ e .harness limpos no Git, para revisar e desfazer.
git -C "${ROOT_DIR}" rev-parse --is-inside-work-tree >/dev/null 2>&1 ||
  { echo "[FAIL] --apply exige repositório Git (para revisar e desfazer a mudança)." >&2; exit 1; }
if [[ -n "$(git -C "${ROOT_DIR}" status --porcelain -- "${APP_DIR}" .harness)" ]]; then
  echo "[FAIL] ${APP_DIR}/ ou .harness com alterações não commitadas; faça commit antes de aplicar." >&2; exit 1
fi
insert_before() {  # <arquivo> <marcador> <bloco>: insere o bloco antes da primeira ocorrência
  awk -v marker="$2" -v block="$3" '
    BEGIN { while ((getline line < block) > 0) text = text line "\n" }
    !done && index($0, marker) { printf "%s", text; done = 1 }
    { print }' "$1" > "$1.tmp" && mv "$1.tmp" "$1"
}
insert_before "${POM}" '</properties>' "${BLOCKS}/xml-1"
insert_before "${POM}" '</dependencies>' "${BLOCKS}/xml-2"
# Sem <plugins>, a seção é criada (dentro de <build>, ou um <build> novo antes de </project>).
if grep -qF '</plugins>' "${POM}"; then
  insert_before "${POM}" '</plugins>' "${BLOCKS}/xml-3"
else
  wrapped="${BLOCKS}/plugins-wrapped"
  if grep -qF '</build>' "${POM}"; then
    { printf '\t\t<plugins>\n'; cat "${BLOCKS}/xml-3"; printf '\t\t</plugins>\n'; } > "${wrapped}"
    insert_before "${POM}" '</build>' "${wrapped}"
  else
    { printf '\t<build>\n\t\t<plugins>\n'; cat "${BLOCKS}/xml-3"; printf '\t\t</plugins>\n\t</build>\n'; } > "${wrapped}"
    insert_before "${POM}" '</project>' "${wrapped}"
  fi
fi
for rel in "${!classes[@]}"; do
  mkdir -p "$(dirname -- "${test_dir}/${rel}")"
  cp "${classes[${rel}]}" "${test_dir}/${rel}"
done
sed -i 's/^QUALITY_GATES=.*/QUALITY_GATES=required/' "${ROOT_DIR}/.harness"
grep -qx 'QUALITY_GATES=required' "${ROOT_DIR}/.harness" || printf 'QUALITY_GATES=required\n' >> "${ROOT_DIR}/.harness"
echo "[PASS] Quality gates aplicados. Próximos passos: git diff; bash scripts/verify.sh; bash scripts/quality/mutation.sh."
echo "       Para desfazer: git checkout -- ${APP_DIR} .harness && git clean -fd ${APP_DIR}/src/test"
