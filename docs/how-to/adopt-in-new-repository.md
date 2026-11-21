# Aplicar esta configuração AI-First em outro repositório

Guia para levar a configuração AI-First deste repositório (instruções e skills dos agentes, harness, PRD guiado, ADRs) a outro projeto. Tudo parte do exportador `scripts/agents/export-kit.sh`, que copia só o que é reutilizável, remove o que é específico deste produto e verifica o resultado antes de gravar. O seed público é a mesma exportação com um app mínimo, publicada como template ([ADR-0005](../architecture/adr/0005-public-seed-repository.md)).

## Layout de destino

A configuração AI-First fica na **raiz** e vale para o repositório inteiro, porque os agentes podem alterar qualquer diretório. O projeto Maven fica **sempre** em `app/` (`app/pom.xml`). Detalhes e regras por diretório: [layout do repositório](../architecture/repository-layout.md).

```text
<repositório>/
├── AGENTS.md, CLAUDE.md, .agents/, .claude/, .codex/   instruções e skills (raiz)
├── docs/, scripts/, .harness                           documentação, harness e configuração dele
├── app/                                                projeto Maven (app/pom.xml)
├── infra/, tests/                                      infraestrutura e testes fora do app
└── .github/                                            do time de DevOps: o kit não grava aqui, e agentes não alteram
```

## Pré-requisitos

- **Stack que o harness assume:** Java, Maven Wrapper em `app/` e Spring Boot; Testcontainers com PostgreSQL para a integração. Para outras stacks, veja [Outras stacks](#outras-stacks).
- Bash (Git Bash no Windows), Git e Docker. Opcionais: `gh`, k6 e gitleaks (sem gitleaks, a varredura usa Docker).

## Escolher o caminho

| Caminho | Quando usar | O que o destino recebe |
|---|---|---|
| [Projeto existente](#projeto-existente-só-configuração) | Já existe um projeto com `app/` | **Só a configuração AI-First.** Nada em `app/`, `infra/`, `tests/` ou `.github/` é criado ou alterado |
| [Seed público](#seed-público) | Projeto novo, do zero | Configuração + `app/` compilável sem negócio + `infra/` e `tests/` |

## Projeto existente: só configuração

```bash
bash scripts/agents/export-kit.sh ../orders-service --project-name "Orders Service"
```

| Grupo | Arquivos na raiz do destino | Depois |
|---|---|---|
| Contexto dos agentes | `AGENTS.md`, `CLAUDE.md`, `.agents/skills/`, `.claude/settings.json`, `.codex/` | **Adaptar** o `AGENTS.md` §1 (propósito) e §2 (stack, preenchido com o que foi detectado em `app/pom.xml`) |
| Harness | `scripts/`, `.harness` (`APP_DIR=app`, `QUALITY_GATES=optional`), `.editorconfig`, `.gitattributes`, `.gitignore`, `.gitleaks.toml` | Genérico |
| Documentação de engenharia | `docs/ai/`, `docs/engineering/`, `docs/architecture/` (convenções, regras, layout, ADRs 0001 a 0003), `docs/features/`, `docs/how-to/run-tests.md`, `docs/how-to/enable-quality-gates.md` | ADRs entram como **Proposta (herdada do kit)**: revise e aceite |
| Produto | `docs/product/TEMPLATE.md` e `docs/product/prd.md` | O time de negócio preenche o PRD |
| Ambiente e governança | `.devcontainer/`, `SECURITY.md`, `CONTRIBUTING.md`, `README.md` (se não existir) | Licença no `CONTRIBUTING.md` |
| Não vai | `.github/`, `src/`, `pom.xml`, testes, PRD-001, FEAT-0001, `docs/reference/`, ADR-0004, ADR-0005, entradas do registro de aprendizados, `LICENSE`, `NOTICE` | `.github/` é do time de DevOps; o restante é deste produto ou decisão do novo dono |

O exportador:

- **lê** `app/` (sem gravar) para detectar a classe `@SpringBootApplication`, o pacote base, o `java.version` e a versão do Spring Boot. O pacote substitui o deste repositório nas skills e nos documentos;
- monta o kit numa área temporária, recusa qualquer arquivo sob `app/`, `infra/`, `tests/` ou `.github/`, roda o `check-config.sh` e só então copia. Se algo falhar, o destino não é alterado;
- **nunca sobrescreve**: arquivo de configuração que já existe e difere recebe a versão do kit como `<arquivo>.kit`, para você mesclar.

Os quality gates dependem do `app/pom.xml`, que o kit não altera. Com `QUALITY_GATES=optional`, cada gate não configurado retorna SKIP com o motivo, e o `verify.sh` termina PARCIAL. Para ativá-los, siga [Ativar os quality gates](enable-quality-gates.md).

Validação real (2026-11-21), com um app do Spring Initializr em `app/` (Boot 4.2.0, Java 17, só webmvc): `app/` ficou byte a byte igual, e o `verify.sh` deu Agentes e Build **PASS**; Unitários SKIP com aviso do `DemoApplicationTests` (`*Tests` não segue a convenção); Arquitetura, Integração e Cobertura SKIP → PARCIAL.

## Seed público

O repositório [java-ai-first-seed](https://github.com/wesleyosantos91/java-ai-first-seed) é um *GitHub Template*: a configuração acima, mais `app/` com uma aplicação Spring Boot mínima (`com.example.seed.SeedApplication`, sem endpoints) e os gates configurados (`QUALITY_GATES=required`), `infra/`, `tests/performance/k6/smoke.js`, `LICENSE`/`NOTICE` e um README de uso. Não traz `.github/`.

1. *Use this template* no GitHub e clone o repositório criado.
2. Dê nome ao projeto (pacote, classe principal, `groupId`/`artifactId` em `app/pom.xml`, `spring.application.name`, devcontainer e README):

   ```bash
   bash scripts/agents/init-project.sh --base-package com.acme.orders \
     --main-class OrdersApplication --project-name "Orders Service"
   ```

   O script recusa um projeto já inicializado e uma working tree com alterações; não faz commit. Revise com `git diff`.
3. O time de negócio preenche `docs/product/prd.md`. Cada seção indica quem preenche (Negócio, Engenharia ou Ambos) e se é obrigatória; `bash scripts/product/check-prd.sh` lista o que falta por responsável. Um PRD com Status Aprovado e campos pendentes reprova o `check-config`.
4. Siga [Depois da exportação](#depois-da-exportação).

**Manter o seed:** ele só muda por regeneração. A partir deste repositório, `bash scripts/agents/export-kit.sh <diretório-vazio> --seed`, `bash scripts/verify.sh` no resultado, e a publicação da diferença no repositório do seed por pull request. Correções feitas direto no seed se perdem na próxima geração.

## Depois da exportação

1. **Adaptar:** `AGENTS.md` §1 e §2; licença (`LICENSE`/`NOTICE` e seção "Licença" do `CONTRIBUTING.md`); versões em `.devcontainer/devcontainer.json`. Se o app expõe JSON, considere `spring.jackson.deserialization.fail-on-unknown-properties: true` e `spring.mvc.problemdetails.enabled: true` no `application.yaml`. Isso é mudança no app, e exige autorização.
2. **Contrato e decisões:** PRD aprovado por revisão humana; ADRs herdados (0001 a 0003) aceitos, ajustados por novo ADR ou rejeitados, com o índice atualizado.
3. **`.github/`:** workflows, CODEOWNERS e templates ficam com o time de DevOps. O `.claude/settings.json` nega a edição de `.github/**` aos agentes.
4. **Ativar e verificar:**

   ```bash
   git init                                 # se ainda não for um repositório
   bash scripts/git/install-hooks.sh        # commit-msg e pre-commit
   bash scripts/setup.sh                    # Java (comparado ao app/pom.xml), Maven Wrapper, Docker, hooks
   bash scripts/agents/check-config.sh      # contexto dos agentes, links, marcadores, .harness, PRD
   bash scripts/harness-tests/harness.sh    # contratos do harness (Maven/Docker simulados)
   bash scripts/verify.sh                   # fluxo padrão, com o Maven em app/
   ```

   Sem código de negócio, ou com gates opcionais, o `verify.sh` termina PARCIAL. **Isso é esperado:** a primeira feature e a ativação dos gates tiram o fluxo desse estado.
5. **Providers de IA:** no Codex, marque o projeto como confiável para carregar `.codex/`; no Claude Code, confira com `/skills` que as skills aparecem; o Devin lê `AGENTS.md` e `.agents/skills/` sem configuração extra.
6. **Primeira feature:** registre a demanda com a skill `requirements-discovery` ou `spec-driven-development` (`docs/features/FEAT-0001-*/spec.md`), aprove o escopo e siga a skill `feature-delivery`.

Trechos específicos deste repositório dentro de documentos genéricos são tratados por marcadores invisíveis: `<!-- kit:omit-line -->`, `<!-- kit:replace-line: TEXTO -->` e `<!-- kit:omit-start -->`…`<!-- kit:omit-end -->`, validados pelo `check-config.sh`. Ao escrever aqui um trecho que só vale para este produto, marque-o.

## Outras stacks

| Parte | Reaproveitamento |
|---|---|
| `scripts/agents/`, `scripts/git/`, `scripts/security/`, `scripts/product/`, `.agents/`, `.claude/`, `.codex/`, `docs/` | Como estão (a documentação de testes precisa refletir a nova ferramenta) |
| `scripts/build/`, `scripts/test/`, `scripts/quality/`, `scripts/lib/test-suite.sh` | Reescrever para a ferramenta da stack, **mantendo o contrato** de saída `0` PASS, `3` SKIP, `1` FAIL e a regra "SKIP não é PASS" |
| `ArchitectureTest`, `TestcontainersConfiguration` | Substituir pelo equivalente da stack |
| `scripts/harness-tests/` | Adaptar os testes que simulam Maven (`harness.sh`) e os que usam Maven real |

## Diagnóstico

- **`check-config` acusa link quebrado no destino:** um trecho específico deste repositório não foi marcado. Marque-o aqui com `kit:omit-line` ou `kit:replace-line` e exporte de novo (`scripts/harness-tests/export-kit.sh` reproduz o caso).
- **`app/pom.xml ou Maven Wrapper (app/mvnw) não encontrado`:** o projeto Maven precisa estar em `app/`, com o Maven Wrapper.
- **`<gate> não configurado em app/pom.xml`:** esperado com `QUALITY_GATES=optional`; veja [Ativar os quality gates](enable-quality-gates.md).
- **`.harness: APP_DIR=...; em projetos o pom fica em app/`:** use `APP_DIR=app`.
- **`AGENTS.md` acima do limite:** o orçamento de 12 KB vale também no destino. Mova detalhes para `docs/how-to/` ou skills.
- **Stubs divergentes:** depois de editar uma skill, rode `bash scripts/agents/sync-skills.sh`.
