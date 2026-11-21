# Aplicar a configuração AI-First num monorepo existente

O kit leva a configuração AI-First deste repositório (instruções e skills dos agentes, harness, PRD guiado, ADRs propostos) para um **monorepo que já existe**, com o projeto Maven em `app/`. Ele não cria projeto e não altera o que o time já tem: grava só configuração na raiz ([ADR-0005](../architecture/adr/0005-public-seed-repository.md)).

## Layout esperado

```text
<monorepo>/
├── app/        projeto Maven (app/pom.xml): obrigatório
├── infra/      infraestrutura (por exemplo, Terraform): opcional
├── tests/      testes fora do app: opcional
├── .github/    CI do time de DevOps: opcional
└── README.md   do projeto: opcional
```

Depois da instalação, a raiz recebe `AGENTS.md`, `CLAUDE.md`, `.agents/`, `.claude/`, `.codex/`, `.devcontainer/`, `docs/`, `scripts/`, `.harness` e os arquivos de editor e Git (`.editorconfig`, `.gitattributes`, `.gitignore`, `.gitleaks.toml`), além de `CONTRIBUTING.md` e `SECURITY.md`. As regras por diretório estão no [layout do repositório](../architecture/repository-layout.md).

## Pré-requisitos

- Bash (Git Bash no Windows), Git e Docker. Opcionais: k6 e gitleaks (sem gitleaks, a varredura usa Docker).
- O `app/` com `pom.xml`, Maven Wrapper (`app/mvnw`) e uma classe `@SpringBootApplication`.

## Instalar: um comando, só o diretório

Pelo seed público, que é o instalador:

```bash
git clone https://github.com/wesleyosantos91/java-ai-first-seed.git
bash java-ai-first-seed/install.sh /caminho/do/monorepo
```

Ou a partir deste repositório, com o mesmo resultado:

```bash
bash scripts/agents/export-kit.sh /caminho/do/monorepo
```

O instalador:

1. **Detecta** em `app/`, só por leitura: a classe `@SpringBootApplication`, o pacote, o `java.version`, o Spring Boot, os starters e o nome do projeto (`<name>` ou `<artifactId>` do `app/pom.xml`, ou o nome do diretório).
2. **Monta a configuração** numa área temporária, com os valores detectados: pacote nas skills e nos documentos, stack no `AGENTS.md` §2, blocos de quality gates com o pacote do projeto e `.harness` com `APP_DIR=app` e `QUALITY_GATES=optional`.
3. **Verifica** essa configuração com o `check-config.sh` e recusa qualquer arquivo sob `app/`, `infra/`, `tests/`, `.github/` ou no `README.md`.
4. **Copia sem sobrescrever:** se um arquivo de configuração já existe e é diferente, a versão do kit fica ao lado como `<arquivo>.kit`, para mesclar.

Se qualquer etapa falhar, o projeto não é alterado. Nada do instalador (`install.sh`, `payload/`, `templates/`) vai para o projeto, que não depende do seed nem deste repositório.

Validação real (2026-11-21), com um app do Spring Initializr em `app/` (Boot 4.2.0, Java 17, só webmvc): `app/` e `infra/` ficaram byte a byte iguais. O `verify.sh` deu Agentes e Build **PASS**; Unitários SKIP, com aviso sobre o `DemoApplicationTests` (`*Tests` não segue a convenção); Arquitetura, Integração e Cobertura SKIP por não estarem configuradas → PARCIAL.

## Depois de instalar

Tudo que precisa ser preenchido já vem com a seção pronta e com o campo marcado por responsável: `[PREENCHER-NEGÓCIO: ...]` ou `[PREENCHER-ENGENHARIA: ...]`.

```bash
bash scripts/agents/list-pending.sh   # todos os campos, por responsável, com arquivo e linha
bash scripts/product/check-prd.sh     # PRD
```

| Quem | O quê |
|---|---|
| Negócio | PRD em `docs/product/prd.md` (cada seção diz quem preenche e se é obrigatória) e propósito no `AGENTS.md` §1 |
| Engenharia | Seção "Revisão neste projeto" dos ADRs 0001 a 0003 (Aceita, Rejeitada ou Substituída) e atualização do índice; persistência no `AGENTS.md` §2; licença no `CONTRIBUTING.md` |
| Engenharia | Quality gates: copiar os blocos prontos do fim de `docs/how-to/enable-quality-gates.md` para o `app/pom.xml` e `app/src/test/java`, e trocar para `QUALITY_GATES=required` no `.harness`. É mudança no app e exige autorização |
| DevOps | `.github/` continua com o time. O `.claude/settings.json` nega aos agentes a edição de `.github/**` |

Ative e verifique:

```bash
git init                                 # se ainda não for um repositório
bash scripts/git/install-hooks.sh        # commit-msg e pre-commit
bash scripts/setup.sh                    # Java (comparado ao app/pom.xml), Maven Wrapper, Docker, hooks
bash scripts/agents/check-config.sh      # contexto dos agentes, links, .harness, PRD
bash scripts/verify.sh                   # fluxo padrão, com o Maven em app/
```

Com gates opcionais ou sem código de negócio, o `verify.sh` termina PARCIAL. **Isso é esperado:** a ativação dos gates e a primeira feature tiram o fluxo desse estado. Providers: no Codex, marque o projeto como confiável para carregar `.codex/`; no Claude Code, confira com `/skills` que as skills aparecem; o Devin lê `AGENTS.md` e `.agents/skills/` sem configuração extra. Primeira feature: skill `requirements-discovery` ou `spec-driven-development`, depois `feature-delivery`.

## Manter o seed

O seed só muda por regeneração a partir deste repositório: `bash scripts/agents/export-kit.sh --seed <diretório-vazio>`, que verifica a instalação num projeto de exemplo antes de gravar, e a publicação da diferença no repositório do seed por pull request. Correções feitas direto no seed se perdem na próxima geração.

O que vai para o projeto sai deste repositório. Trechos que só valem aqui são tratados por marcadores invisíveis nos Markdown: `<!-- kit:omit-line -->`, `<!-- kit:replace-line: TEXTO -->` e `<!-- kit:omit-start -->`…`<!-- kit:omit-end -->`, validados pelo `check-config.sh`. Ao escrever aqui um trecho que só vale para este produto, marque-o. O teste `bash scripts/harness-tests/export-kit.sh` aplica o kit num monorepo de exemplo (`app/`, `infra/` com Terraform, `tests/`, `.github/`, README), pelos dois caminhos, e confere por hash que nada do projeto mudou.

## Outras stacks

| Parte | Reaproveitamento |
|---|---|
| `scripts/agents/`, `scripts/git/`, `scripts/security/`, `scripts/product/`, `.agents/`, `.claude/`, `.codex/`, `docs/` | Como estão (a documentação de testes precisa refletir a nova ferramenta) |
| `scripts/build/`, `scripts/test/`, `scripts/quality/`, `scripts/lib/test-suite.sh` | Reescrever para a ferramenta da stack, **mantendo o contrato** de saída `0` PASS, `3` SKIP, `1` FAIL e a regra "SKIP não é PASS" |
| `ArchitectureTest`, `TestcontainersConfiguration` | Substituir pelo equivalente da stack |

## Diagnóstico

- **`app/pom.xml não encontrado`:** o kit configura um monorepo existente; o projeto Maven precisa estar em `app/`.
- **`Classe @SpringBootApplication não encontrada`:** a classe principal precisa estar em `app/src/main/java`.
- **`check-config` acusa link quebrado:** um trecho específico deste repositório não foi marcado. Marque-o aqui com `kit:omit-line` ou `kit:replace-line` e regenere (`scripts/harness-tests/export-kit.sh` reproduz o caso).
- **`<gate> não configurado em app/pom.xml`:** esperado com `QUALITY_GATES=optional`; veja [Ativar os quality gates](enable-quality-gates.md).
- **`.harness: APP_DIR=...; em projetos o pom fica em app/`:** use `APP_DIR=app`.
- **`AGENTS.md` acima do limite:** o orçamento de 12 KB vale também no projeto. Mova detalhes para `docs/how-to/` ou skills.
