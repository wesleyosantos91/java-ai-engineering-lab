#!/usr/bin/env bash
# Compartilhado pelos scripts de qualidade; não deve ser executado diretamente.
# Lê uma propriedade simples do pom.xml (por exemplo app.basePath) sem invocar o Maven.
# Retorna 1, com mensagem, se a propriedade não existir: o harness não adivinha o pacote base.
pom_property() {
  local name="$1" value
  value="$(sed -n "s#.*<${name}>\([^<]*\)</${name}>.*#\1#p" "${ROOT_DIR}/pom.xml" | head -n 1)"
  if [[ -z "${value}" ]]; then
    echo "[FAIL] Propriedade <${name}> ausente no pom.xml; defina app.basePackage, app.basePath e app.mainClass." >&2
    return 1
  fi
  printf '%s\n' "${value}"
}
