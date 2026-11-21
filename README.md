# Java AI Engineering Lab

Repositório de referência de como configurar um projeto Java **AI-First** com boas práticas: agentes de IA (Codex, Claude Code e Devin) trabalhando sob regras explícitas de engenharia, com **context engineering**, **harness engineering**, PRD como contrato de produto, ADRs como histórico de decisões, testes automatizados, evidências verificáveis e revisão humana ([ADR-0004](docs/architecture/adr/0004-ai-first-reference-repository.md)).

A aplicação-exemplo é uma **Product Catalog API** (CRUD de produtos com PostgreSQL), definida no [PRD-001](docs/product/prd.md). Copie a estrutura e adapte o contrato ao seu domínio.

> [!NOTE]
> A configuração AI-First e o harness estão operacionais. A primeira feature, [FEAT-0001 — criar produto](docs/features/FEAT-0001-create-product/spec.md), demonstra o fluxo completo (spec aprovada → TDD → quality gates) e aguarda revisão humana. Consulte o [catálogo de features](docs/features/README.md).

## O que este repositório demonstra

| Prática | Onde |
|---|---|
| Instruções canônicas e contexto em camadas | [`AGENTS.md`](AGENTS.md), [context engineering](docs/ai/context-engineering.md) |
| Um conjunto de regras para vários providers | [`CLAUDE.md`](CLAUDE.md), `.claude/`, `.codex/`, [ADR-0002](docs/architecture/adr/0002-multi-provider-agent-context.md) |
| Procedimentos sob demanda (Agent Skills) | [`.agents/skills/`](.agents/skills/) |
| Contrato de produto e de features | [PRD](docs/product/prd.md), [catálogo de features](docs/features/README.md) |
| Histórico de decisões | [ADRs](docs/architecture/adr/README.md) |
| Harness sem falso PASS e quality gates | [`scripts/`](scripts/), [guia de testes](docs/how-to/run-tests.md), [ADR-0003](docs/architecture/adr/0003-test-suites-and-quality-gates.md) |
| Aprendizado contínuo versionado | [skill lessons-learned](.agents/skills/lessons-learned/SKILL.md), [registro](docs/ai/lessons-learned.md) |
| Reaproveitamento em outros repositórios | [Guia de adoção](docs/how-to/adopt-in-new-repository.md) e `scripts/agents/export-kit.sh` |
| Regras de commit aplicadas por hooks, não só por texto | `scripts/git/` (`check-commit-msg.sh`, `install-hooks.sh`), [CONTRIBUTING](CONTRIBUTING.md) |
| Segurança e governança | [SECURITY.md](SECURITY.md), varredura de segredos (`scripts/security/`), [CODEOWNERS](.github/CODEOWNERS), templates de issue e PR |
| Ambiente reproduzível para agentes em nuvem | [`.devcontainer/`](.devcontainer/devcontainer.json) (Java 27, Docker, gh) |

## Sumário

- [O que este repositório demonstra](#o-que-este-repositório-demonstra)
- [Estado atual](#estado-atual)
- [Stack](#stack)
- [Início rápido](#início-rápido)
- [Harness de engenharia](#harness-de-engenharia)
- [Desenvolvimento com agentes de IA](#desenvolvimento-com-agentes-de-ia)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Documentação](#documentação)
- [Contribuição](#contribuição)

## Estado atual

| Área | Situação |
|---|---|
| Contrato do produto ([PRD-001](docs/product/prd.md)) | ✅ Versão 1.0 aprovada; 📝 versão 1.1 (novo propósito) aguardando aprovação |
| Princípios de arquitetura ([ADR-0001](docs/architecture/adr/0001-architecture-principles.md)) | ✅ Aceito |
| Contexto multi-provider, quality gates e repositório de referência ([ADR-0002](docs/architecture/adr/0002-multi-provider-agent-context.md), [ADR-0003](docs/architecture/adr/0003-test-suites-and-quality-gates.md), [ADR-0004](docs/architecture/adr/0004-ai-first-reference-repository.md)) | 📝 Propostos, aguardando revisão humana |
| Harness local (`scripts/`) | ✅ Operacional: build, suítes unitária e de integração separadas, guard de branch |
| Teste de integração de infraestrutura | ✅ `JavaAiEngineeringLabApplicationIT` (contexto Spring e PostgreSQL 18.2 via Testcontainers) |
| Instruções e skills para agentes | ✅ [`AGENTS.md`](AGENTS.md) e [`.agents/skills/`](.agents/skills/), com adaptadores para Codex e Claude Code verificados por `scripts/agents/check-config.sh` |
| `POST /api/v1/products` ([FEAT-0001](docs/features/FEAT-0001-create-product/spec.md)) | 🔎 Implementado com TDD, em validação (aguardando revisão humana); [referência da API](docs/reference/api/products.md) |
| Consulta, listagem, atualização e exclusão | ⏳ Especificadas no PRD, não implementadas |
| Migrações Flyway | ✅ `V1__create_product.sql` (tabela `product` com restrições de integridade) |
| Testes de produto | ✅ 57 unitários (domain e service) e 32 de integração HTTP + PostgreSQL, incluindo concorrência |
| Quality gates (JaCoCo, ArchUnit, PIT) | ✅ JaCoCo LINE 99,32% e BRANCH 95,65%; PIT 100% (43/43); ArchUnit com 8 regras aprovadas e 3 não aplicáveis (N/A: exigem duas features ou mensageria) |
| Smoke de performance (k6) | ✅ `scripts/performance/smoke.sh` contra `/actuator/health`; valida disponibilidade, não desempenho |
| Observabilidade (Datadog), load e stress (k6) | ⏳ Planejados para a primeira feature com endpoint ([skill performance-optimization](.agents/skills/performance-optimization/SKILL.md)) |

## Stack

| Componente | Versão / escolha |
|---|---|
| Linguagem | Java 27 |
| Framework | Spring Boot 4.1.2 (Spring Web MVC) |
| Persistência | Spring JDBC com SQL explícito; sem JPA ([ADR-0001](docs/architecture/adr/0001-architecture-principles.md)) |
| Banco de dados | PostgreSQL, com esquema versionado por Flyway |
| Testes | JUnit Jupiter 6, Surefire (`*Test`) e Failsafe (`*IT`), Testcontainers com PostgreSQL 18.2 fixado por digest |
| Quality gates | JaCoCo 0.8.16, ArchUnit 1.5.1, PIT 1.30.1 ([detalhes](docs/how-to/run-tests.md#quality-gates)) |
| Build | Maven 3.10.0 via Maven Wrapper 3.3.4 |
| Arquitetura | Feature-Based pragmática, package base `io.github.wesleyosantos91.catalog` |

## Início rápido

### Pré-requisitos

- Bash compatível (no Windows, Git Bash).
- Java 27 no `PATH`. Não é preciso instalar Maven: o wrapper o resolve.
- Docker funcional, necessário para os testes de integração.

### Clonar e verificar

```bash
git clone https://github.com/wesleyosantos91/java-ai-engineering-lab.git
cd java-ai-engineering-lab
bash scripts/setup.sh    # inspeciona Java, Maven Wrapper e Docker
bash scripts/verify.sh   # build, testes unitários e de integração
```

O `verify.sh` termina com um resumo por etapa (`PASS`, `FAIL`, `SKIP` ou `NOT RUN`). No estado atual, sem código de negócio, as etapas unitária, de arquitetura e de cobertura retornam `SKIP` e o resultado agregado é **PARCIAL**. Isso é esperado e **não** equivale a aprovação. A mutação exige execução explícita com `bash scripts/quality/mutation.sh`. Detalhes, códigos de saída e diagnóstico estão no [guia de testes](docs/how-to/run-tests.md).

## Harness de engenharia

Scripts versionados em `scripts/`, organizados por domínio e preferidos a comandos Maven avulsos por pessoas e agentes. Os pontos de entrada ficam na raiz:

```text
scripts/
├── setup.sh                 # inspecionar ambiente, versões e Docker
├── verify.sh                # fluxo padrão: agentes, build, unitários, arquitetura, integração, cobertura
├── build/compile.sh         # compilar com o Maven Wrapper
├── test/                    # unit.sh (*Test), architecture.sh (*ArchitectureTest), integration.sh (*IT)
├── quality/                 # coverage.sh (JaCoCo ≥ 90%), mutation.sh (PIT ≥ 90%, explícito)
├── performance/smoke.sh     # smoke k6 de disponibilidade (explícito)
├── agents/                  # check-config.sh, sync-skills.sh e hooks dos providers
├── git/                     # guard-branch.sh, check-commit-msg.sh, install-hooks.sh e hooks/
├── security/scan-secrets.sh # varredura de segredos com gitleaks (explícito e no pre-commit)
├── lib/                     # helpers compartilhados (não executáveis isoladamente)
└── harness-tests/           # testes do próprio harness
```

Todos usam o mesmo contrato de saída: `0` PASS, `3` SKIP e `1` FAIL.

`SKIP_INTEGRATION=1 bash scripts/verify.sh` omite a integração e produz resultado **parcial**. Use apenas com justificativa comunicada. As regras completas estão no [AGENTS.md, seção 7](AGENTS.md#7-harness-local).

## Desenvolvimento com agentes de IA

A configuração tem **uma fonte canônica** e adaptadores finos por provider ([ADR-0002](docs/architecture/adr/0002-multi-provider-agent-context.md)):

- **[`AGENTS.md`](AGENTS.md)** é o ponto de entrada, carregado em toda sessão e mantido abaixo de 12 KB: stack, regras arquiteturais, fluxo de trabalho, harness, segurança, Git e formato obrigatório de relatório.
- **[`.agents/skills/`](.agents/skills/)** reúne procedimentos especializados no formato aberto [Agent Skills](https://agentskills.io/specification), carregados sob demanda. O catálogo completo está no [AGENTS.md, seção 3](AGENTS.md#skills).

| Provider | Lê | Adaptador versionado |
|---|---|---|
| Codex | `AGENTS.md`, `.agents/skills/` | `.codex/config.toml` e `.codex/rules/` (sandbox e aprovação de comandos de entrega) |
| Claude Code | [`CLAUDE.md`](CLAUDE.md), que importa o `AGENTS.md`, e `.claude/skills/` | Stubs de skills gerados; `.claude/settings.json` com permissões e hook de branch |
| Devin | `AGENTS.md`, `.agents/skills/` | Nenhum necessário |

As camadas de contexto, o papel de PRD e ADRs e como evoluir a configuração estão em [Context engineering e harness para agentes](docs/ai/context-engineering.md).

Fluxo ordinário de uma entrega:

```text
requirements-discovery → spec-driven-development → implementation-planning
→ tdd-workflow + plan-execution → code-simplification
→ verification-before-completion → code-review → git-delivery
```

Princípios que valem para qualquer agente:

- Nenhuma conclusão sem evidência executada; `SKIP` e `NOT RUN` não são `PASS`.
- Contratos aprovados (PRD, ADRs, critérios de aceitação) não são alterados para acomodar a implementação.
- Commit, push e merge exigem autorização humana explícita.
- Decisões arquiteturais relevantes e a conclusão de features exigem revisão humana.

## Estrutura do repositório

```text
.
├── AGENTS.md                  # instruções canônicas para agentes de IA
├── CLAUDE.md                  # adaptador do Claude Code (importa AGENTS.md)
├── .agents/skills/            # skills de agente canônicas (SKILL.md)
├── .claude/                   # stubs de skills gerados e settings do Claude Code
├── .codex/                    # config e regras de comando do Codex
├── .devcontainer/             # ambiente reproduzível (Codespaces e agentes em nuvem)
├── .github/                   # CODEOWNERS, templates de issue e de pull request
├── CONTRIBUTING.md            # fluxo de contribuição
├── LICENSE, NOTICE            # Apache License 2.0 e atribuição
├── SECURITY.md                # política e reporte de vulnerabilidades
├── docs/
│   ├── product/               # PRD
│   ├── architecture/          # ADRs (índice e template), packages e regras de dependência
│   ├── engineering/           # Definition of Done
│   ├── features/              # catálogo e template de especificação
│   ├── how-to/                # guias operacionais
│   └── ai/                    # context engineering e aprendizados registrados
├── performance/k6/            # cenários k6 (smoke de disponibilidade)
├── scripts/                   # harness local
└── src/                       # código e testes Java
```

## Documentação

**Produto e escopo**
- [PRD-001 — Product Catalog API](docs/product/prd.md): requisitos, contrato HTTP e critérios BDD
- [Catálogo de features](docs/features/README.md) e [template de especificação](docs/features/TEMPLATE.md)

**Arquitetura**
- [Índice de ADRs, processo e template](docs/architecture/adr/README.md)
- [ADR-0001 — Princípios de arquitetura](docs/architecture/adr/0001-architecture-principles.md)
- [Convenções de packages](docs/architecture/package-conventions.md)
- [Regras de dependência](docs/architecture/dependency-rules.md)

**Engenharia**
- [Definition of Done](docs/engineering/definition-of-done.md)
- [Executar e diagnosticar testes](docs/how-to/run-tests.md)
- [Aplicar esta configuração em um repositório novo](docs/how-to/adopt-in-new-repository.md)
- [Como contribuir](CONTRIBUTING.md)

**Agentes de IA**
- [AGENTS.md](AGENTS.md) e [CLAUDE.md](CLAUDE.md)
- [Context engineering e harness para agentes](docs/ai/context-engineering.md)
- [Registro de aprendizados](docs/ai/lessons-learned.md) e [skill lessons-learned](.agents/skills/lessons-learned/SKILL.md)
- [Skill feature-delivery](.agents/skills/feature-delivery/SKILL.md) (entrega funcional)
- [Skill project-documentation](.agents/skills/project-documentation/SKILL.md) (documentação)

## Contribuição

O fluxo de branches, commits, verificações e pull request está no [CONTRIBUTING.md](CONTRIBUTING.md). Resumo: trabalhe em `feature/*`, `fix/*` ou `experiment/*` a partir de `develop`; use Conventional Commits em inglês; execute `bash scripts/git/guard-branch.sh` e `bash scripts/verify.sh` antes do PR e preencha o [template de PR](.github/pull_request_template.md). As regras completas estão no [AGENTS.md, seção 9](AGENTS.md#9-git-e-versionamento).

## Licença

Distribuído sob a [Apache License 2.0](LICENSE). Avisos de atribuição em [NOTICE](NOTICE).
