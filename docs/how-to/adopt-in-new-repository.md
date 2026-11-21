# Aplicar esta configuração AI-First em um repositório novo

Guia para levar a configuração deste repositório (contexto de agentes, harness, PRD/ADR, governança) a outro projeto. Tudo parte do exportador `scripts/agents/export-kit.sh`, que copia só o que é reutilizável, remove o que é específico deste produto e verifica o resultado; o seed público é a mesma exportação, já publicada como template.

## Pré-requisitos

- **Stack que o harness assume:** Java (27), Maven Wrapper, Spring Boot e Testcontainers com PostgreSQL. Para outras stacks, veja [Outras stacks](#outras-stacks).
- Bash (Git Bash no Windows), Git e Docker. Opcionais: `gh`, k6 e gitleaks (sem gitleaks, a varredura usa Docker).
- O repositório novo pode estar vazio ou já ter `README.md`, `.gitignore`, `pom.xml` etc.: o exportador **nunca sobrescreve**. Quando o arquivo já existe, a versão do kit é gravada como `<arquivo>.kit`, para você mesclar.

## O que vai e o que não vai

| Grupo | Arquivos | No repositório novo |
|---|---|---|
| Contexto dos agentes | `AGENTS.md`, `CLAUDE.md`, `.agents/skills/`, `.claude/settings.json`, `.codex/` | **Adaptar** só o `AGENTS.md` (§1 propósito, §2 stack); o resto é genérico |
| Harness | `scripts/` inteiro, `.editorconfig`, `.gitattributes`, `.gitignore`, `.gitleaks.toml` | Genérico; os scripts de qualidade leem o pacote base das propriedades `app.*` do `pom.xml` |
| Build | `pom.xml`, `mvnw`, `.mvn/` | **Adaptar**: `groupId`, `artifactId`, `name`, `description`, `licenses`, dependências |
| Testes de infraestrutura | `TestcontainersConfiguration`, `*ApplicationIT`, `Test*Application`, `architecture/ArchitectureTest` | Genérico após `--base-package` e `--main-class` |
| Documentação de engenharia | `docs/ai/`, `docs/engineering/`, `docs/architecture/` (convenções, regras, índice, template, ADRs 0001 a 0003), `docs/features/` (catálogo vazio e template), `docs/how-to/run-tests.md` | ADRs entram como **Proposta (herdada do kit)**: revise e aceite |
| Produto | `docs/product/TEMPLATE.md` e `docs/product/prd.md` (cópia do template) | **Escrever** o PRD |
| Governança e ambiente | `.github/` (CODEOWNERS, issues, PR), `SECURITY.md`, `CONTRIBUTING.md`, `.devcontainer/`, `performance/k6/smoke.js` | **Adaptar** CODEOWNERS, `OWNER/REPO` nos templates e a licença no `CONTRIBUTING.md` |
| Não vai | `src/main/`, testes de produto, PRD-001, FEAT-0001, `docs/reference/`, ADR-0004, entradas do registro de aprendizados, `README.md`, `LICENSE`, `NOTICE` | Específicos deste produto ou decisão do novo dono. No seed (`--seed`), `README.md`, `LICENSE`, `NOTICE` e uma aplicação mínima em `src/main/` são gerados |

Trechos específicos dentro de documentos genéricos são tratados por marcadores invisíveis nos Markdown deste repositório: `<!-- kit:omit-line -->`, `<!-- kit:replace-line: TEXTO -->` e `<!-- kit:omit-start -->`…`<!-- kit:omit-end -->`. O `scripts/agents/check-config.sh` valida esses marcadores. Ao escrever aqui um trecho que só vale para este produto, marque-o.

## Escolher o caminho

| Caminho | Quando usar |
|---|---|
| [Seed público](#via-seed-público) | Projeto novo, do zero: repositório pronto, compilável e sem negócio, em que o time de negócio começa pelo PRD |
| [Exportador](#via-exportador) | Repositório que já existe, ou personalização do que é copiado |

## Via seed público

O repositório [java-ai-first-seed](https://github.com/wesleyosantos91/java-ai-first-seed) é um *GitHub Template* gerado por este repositório ([ADR-0005](../architecture/adr/0005-public-seed-repository.md)): o kit abaixo mais uma aplicação Spring Boot mínima (`com.example.seed.SeedApplication`, sem endpoints), `LICENSE`/`NOTICE` e um README de uso.

1. *Use this template* no GitHub e clone o repositório criado.
2. Dê nome ao projeto (pacote, classe principal, `groupId`/`artifactId`, `spring.application.name`, devcontainer e README):

   ```bash
   bash scripts/agents/init-project.sh --base-package com.acme.orders \
     --main-class OrdersApplication --project-name "Orders Service"
   ```

   O script recusa um projeto já inicializado e uma working tree com alterações; não faz commit. Revise com `git diff`.
3. O time de negócio preenche `docs/product/prd.md`. Cada seção indica quem preenche (Negócio, Engenharia ou Ambos) e se é obrigatória; `bash scripts/product/check-prd.sh` lista o que falta por responsável. Um PRD com Status Aprovado e campos pendentes reprova o `check-config`.
4. Siga os passos [3. Adaptar](#3-adaptar) a [7. Primeira feature](#7-primeira-feature) abaixo (sem mesclagem: não há `.kit`).

**Manter o seed:** ele só muda por regeneração. A partir deste repositório, `bash scripts/agents/export-kit.sh <diretório-vazio> --seed`, `bash scripts/verify.sh` no resultado, e a publicação da diferença no repositório do seed por pull request. Correções feitas direto no seed se perdem na próxima geração.

## Via exportador

### 1. Exportar

A partir deste repositório:

```bash
bash scripts/agents/export-kit.sh ../orders-service \
  --base-package com.acme.orders \
  --main-class OrdersApplication \
  --project-name "Orders Service"
```

| Opção | Efeito |
|---|---|
| `--base-package` | Troca o pacote base em todos os arquivos, inclusive nas propriedades `app.*` do `pom.xml` e no diretório de `src/test/java` |
| `--main-class` | Troca o nome da classe Spring Boot e renomeia os testes de infraestrutura (`OrdersApplicationIT`, `TestOrdersApplication`) |
| `--project-name` | Nome do projeto nos documentos, no README gerado e no `name` do devcontainer |
| `--seed` | Gera o seed público: nomes fixos (`com.example.seed`, `SeedApplication`, `java-ai-first-seed`), aplicação mínima, `LICENSE`/`NOTICE` e README de uso; não combina com as opções acima |

O exportador monta o kit numa área temporária, roda `scripts/agents/check-config.sh` nele e só então copia para o destino. Se a verificação falhar, o destino não é alterado. Ao final, ele imprime o checklist de adaptação e a lista de arquivos com `[PREENCHER]` ou `[ADAPTAR]`.

### 2. Mesclar conflitos

Para cada `<arquivo>.kit` listado, incorpore o conteúdo do kit ao arquivo existente e apague o `.kit`. Os casos mais comuns:

- **`pom.xml.kit`** (projeto do Spring Initializr): copie as propriedades `app.basePackage`, `app.basePath` e `app.mainClass`, as versões dos quality gates, `skipUnitTests` e `argLine`, e os plugins `maven-dependency-plugin`, Surefire, Failsafe, JaCoCo e PIT, além das dependências de teste (ArchUnit, Testcontainers, `junit-platform-launcher`).
- **`.gitignore.kit`** e **`.gitattributes.kit`**: a versão do kit inclui a do Initializr; adote-a, ou acrescente o bloco "Agentes de IA (arquivos locais)", a exceção `!/scripts/build/` e a regra `* text=auto eol=lf`.
- **`TestcontainersConfiguration.java.kit`**: adote a versão do kit (imagem PostgreSQL fixada por digest e classe pública, reutilizável pelos ITs de outras features).
- **`.mvn/wrapper/maven-wrapper.properties.kit`**: mantenha a versão mais nova (o Initializr pode trazer um Maven mais recente que o do kit) e ajuste o §2 do `AGENTS.md`.
- **`*ApplicationTests.java` do Initializr:** remova-o. A convenção do kit não executa `*Tests` (só `*Test` e `*IT`), e o `*ApplicationIT` exportado cobre o teste de contexto com PostgreSQL.

Foi assim que o kit foi validado: com um projeto gerado pelo Spring Initializr (Boot 4.1.2, Java 27, web, jdbc, flyway, postgresql, validation, actuator, testcontainers), o resultado após a mesclagem foi Agentes, Build, Arquitetura e Integração **PASS**, Unitários e Cobertura **SKIP** (sem código de negócio), e o primeiro commit aceito pelos hooks numa branch de trabalho.

### 3. Adaptar

| Item | Onde |
|---|---|
| Propósito e stack | `AGENTS.md` §1 e §2 |
| Identidade Maven e licença declarada | `pom.xml` |
| Dono das revisões | `.github/CODEOWNERS` |
| Repositório nos templates | `OWNER/REPO` em `.github/ISSUE_TEMPLATE/` |
| Licença | `LICENSE` (e `NOTICE`, se Apache-2.0); seção "Licença" do `CONTRIBUTING.md` |
| Versões do ambiente | `.devcontainer/devcontainer.json` (Java fixado) |
| Configuração JSON da API | Se o projeto expõe JSON, adote em `application.yaml` `spring.jackson.deserialization.fail-on-unknown-properties: true` e `spring.mvc.problemdetails.enabled: true` |

### 4. Contrato e decisões

1. Escreva o PRD em `docs/product/prd.md`, a partir do template, e obtenha aprovação humana.
2. Revise os ADRs herdados (0001 a 0003). Aceite, ajuste por um novo ADR ou rejeite cada um, e atualize o índice em `docs/architecture/adr/README.md`.

### 5. Ativar e verificar

```bash
git init                                 # se ainda não for um repositório
bash scripts/git/install-hooks.sh        # commit-msg e pre-commit
bash scripts/setup.sh                    # Java, Maven Wrapper, Docker, hooks
bash scripts/agents/check-config.sh      # contexto dos agentes, links, marcadores, ignorados
bash scripts/harness-tests/harness.sh    # contratos do harness (Maven/Docker simulados)
bash scripts/verify.sh                   # fluxo padrão
```

Sem código de negócio, unitários, arquitetura e cobertura retornam SKIP e o `verify.sh` termina PARCIAL. **Isso é esperado:** a primeira feature tira o fluxo desse estado.

### 6. Providers de IA

- **Codex:** marque o projeto como confiável para carregar `.codex/config.toml` e `.codex/rules/`.
- **Claude Code:** lê `CLAUDE.md`; confira com `/skills` que as skills aparecem.
- **Devin:** lê `AGENTS.md` e `.agents/skills/` sem configuração extra.

### 7. Primeira feature

Registre a demanda com a skill `requirements-discovery` ou `spec-driven-development` (`docs/features/FEAT-0001-*/spec.md`), aprove o escopo e siga a skill `feature-delivery`.

## Outras stacks

| Parte | Reaproveitamento |
|---|---|
| `scripts/agents/`, `scripts/git/`, `scripts/security/`, `.agents/`, `.claude/`, `.codex/`, `docs/` | Como estão (a documentação de testes precisa refletir a nova ferramenta) |
| `scripts/build/`, `scripts/test/`, `scripts/quality/`, `scripts/lib/test-suite.sh`, `pom.xml` | Reescrever para a ferramenta da stack, **mantendo o contrato** de saída `0` PASS, `3` SKIP, `1` FAIL e a regra "SKIP não é PASS" |
| `ArchitectureTest`, `TestcontainersConfiguration` | Substituir pelo equivalente da stack (por exemplo, regras de dependência com a ferramenta disponível) |
| `scripts/harness-tests/` | Adaptar os testes que simulam Maven (`harness.sh`) e os que usam Maven real |

## Diagnóstico

- **`check-config` acusa link quebrado no destino:** um trecho específico deste repositório não foi marcado. Marque-o aqui com `kit:omit-line` ou `kit:replace-line` e exporte de novo (`scripts/harness-tests/export-kit.sh` reproduz o caso).
- **`Propriedade <app.basePath> ausente`:** o `pom.xml` do destino ainda não recebeu as propriedades `app.*` (passo 2).
- **`AGENTS.md` acima do limite:** o orçamento de 12 KB vale também no destino. Mova detalhes para `docs/how-to/` ou skills.
- **Stubs divergentes:** depois de editar uma skill, rode `bash scripts/agents/sync-skills.sh`.
