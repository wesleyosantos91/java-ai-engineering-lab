#!/usr/bin/env bash
# Compartilhado pelo exportador do kit e pela inicialização do seed (scripts/agents/); não deve ser
# executado diretamente. Troca pacote base, classe principal e textos literais numa árvore.
#
# Os scripts de exportação e inicialização (e o teste deles) ficam fora da troca: guardam os nomes
# do seed e do produto como constantes, e reescrevê-los quebraria a próxima execução. Caminhos
# relativos a scripts/ (alguns não existem no seed nem no projeto gerado).
RENAME_EXCLUDED=(agents/export-kit.sh agents/init-project.sh lib/rename.sh harness-tests/export-kit.sh)

# Arquivos de texto sob <raiz> que contêm <literal>, exceto .git, target e os excluídos.
rename_text_files() {
  local root="$1" literal="$2" file rel excluded skip
  while IFS= read -r file; do
    [[ -n "${file}" ]] || continue
    rel="${file#"${root}"/}" skip=0
    for excluded in "${RENAME_EXCLUDED[@]}"; do [[ "${rel}" == "scripts/${excluded}" ]] && skip=1; done
    (( skip )) || printf '%s\n' "${file}"
  done < <(grep -rlIF --exclude-dir=.git --exclude-dir=target -- "${literal}" "${root}" || true)
}

# Substitui <antigo> por <novo> (literais) em todos os arquivos de texto de <raiz>.
rename_literal() {
  local root="$1" old="$2" new="$3" file pattern replacement
  [[ "${old}" != "${new}" ]] || return 0
  pattern="$(printf '%s' "${old}" | sed 's/[][\.*^$/#&]/\\&/g')"
  replacement="$(printf '%s' "${new}" | sed 's/[\/#&]/\\&/g')"
  while IFS= read -r file; do
    sed -i "s#${pattern}#${replacement}#g" "${file}"
  done < <(rename_text_files "${root}" "${old}")
}

# Pacote base: conteúdo (com.a.b e com/a/b) e diretórios <app>/src/{main,test}/java.
# Uso: rename_package <raiz> <antigo> <novo> [diretório do app, padrão "."]
rename_package() {
  local root="$1" old_package="$2" new_package="$3" app="${4:-.}" old_path new_path tree
  [[ "${old_package}" != "${new_package}" ]] || return 0
  old_path="${old_package//.//}" new_path="${new_package//.//}"
  rename_literal "${root}" "${old_package}" "${new_package}"
  rename_literal "${root}" "${old_path}" "${new_path}"
  for tree in "${root}/${app}/src/main/java" "${root}/${app}/src/test/java"; do
    [[ -d "${tree}/${old_path}" ]] || continue
    mkdir -p "${tree}/${new_path}"
    cp -R "${tree}/${old_path}/." "${tree}/${new_path}/"
    rm -rf "${tree:?}/${old_path}"
    # Remove diretórios intermediários do pacote antigo que ficaram vazios.
    find "${tree}" -mindepth 1 -type d -empty -delete
    [[ -d "${tree}/${new_path}" ]] || { echo "[FAIL] Falha ao mover o pacote em ${tree}." >&2; return 1; }
  done
}

# Classe principal: conteúdo e nomes de arquivo (Main.java, MainIT.java, TestMain.java).
# Uso: rename_main_class <raiz> <antiga> <nova> [diretório do app, padrão "."]
rename_main_class() {
  local root="$1" old_main="$2" new_main="$3" app="${4:-.}" file
  [[ "${old_main}" != "${new_main}" ]] || return 0
  rename_literal "${root}" "${old_main}" "${new_main}"
  [[ -d "${root}/${app}/src" ]] || return 0
  while IFS= read -r -d '' file; do
    mv "${file}" "${file%/*}/$(basename -- "${file}" | sed "s#${old_main}#${new_main}#g")"
  done < <(find "${root}/${app}/src" -type f -name "*${old_main}*" -print0)
}

# Nome do projeto em minúsculas e hifens (artifactId, devcontainer, spring.application.name).
project_slug() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g'
}

# README do projeto com as seções prontas; só os campos [PREENCHER-...] ficam para preencher.
# Uso: write_project_readme <arquivo> <nome do projeto>
write_project_readme() {
  local file="$1" name="$2"
  cat > "${file}" <<README
# ${name}

> **Quem preenche:** Negócio (Visão geral) e Engenharia (Licença). O restante já vem pronto. Pendências do projeto, por responsável: \`bash scripts/agents/list-pending.sh\`.

## Visão geral

[PREENCHER-NEGÓCIO: o que o sistema faz, para quem e qual problema resolve, em duas ou três frases.]

Requisitos e critérios de aceitação: [PRD](docs/product/prd.md).

## Estrutura

| Diretório | Conteúdo |
|---|---|
| \`app/\` | Projeto Maven (\`app/pom.xml\`) |
| \`infra/\`, \`tests/\` | Infraestrutura e testes fora do app |
| \`docs/\` | PRD, decisões de arquitetura (ADRs), features e guias |
| \`AGENTS.md\`, \`.agents/\`, \`scripts/\` | Instruções e skills dos agentes de IA e harness de verificação |
| \`.github/\` | Workflows e templates, mantidos pelo time de DevOps |

Regras por diretório: [layout do repositório](docs/architecture/repository-layout.md).

## Como executar

\`\`\`bash
bash scripts/setup.sh                  # Java, Maven Wrapper, Docker e hooks
bash scripts/verify.sh                 # agentes, build, testes e quality gates
(cd app && ./mvnw spring-boot:run)     # aplicação local
\`\`\`

Detalhes e diagnóstico: [executar e diagnosticar testes](docs/how-to/run-tests.md).

## Contribuição

[CONTRIBUTING.md](CONTRIBUTING.md). Instruções para agentes de IA: [AGENTS.md](AGENTS.md).

## Licença

[PREENCHER-ENGENHARIA: licença do projeto, por exemplo Apache-2.0 ou proprietária.]
README
}
