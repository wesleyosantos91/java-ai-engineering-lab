# Java AI Engineering Lab

Laboratório para estudar, implementar e avaliar desenvolvimento **AI-First** com Java, usando agentes de IA sob regras explícitas de engenharia: contratos aprovados, testes automatizados, evidências verificáveis e revisão humana.

O domínio de estudo é uma **Product Catalog API** (CRUD de produtos com PostgreSQL), definida no [PRD-001](docs/product/prd.md).

> [!NOTE]
> O projeto está na fase de **fundação**. O contrato do produto está aprovado e o harness de engenharia está operacional, mas **nenhuma feature de produto foi implementada** ainda. Consulte o [catálogo de features](docs/features/README.md).

## Sumário

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
| Contrato do produto ([PRD-001](docs/product/prd.md)) | ✅ Aprovado (versão 1.0) |
| Princípios de arquitetura ([ADR-0001](docs/architecture/adr/0001-architecture-principles.md)) | ✅ Aceito |
| Harness local (`scripts/`) | ✅ Operacional: build, suítes unitária e de integração separadas, guard de branch |
| Teste de integração de infraestrutura | ✅ `JavaAiEngineeringLabApplicationIT` (contexto Spring e PostgreSQL 18.2 via Testcontainers) |
| Instruções e skills para agentes | ✅ [`AGENTS.md`](AGENTS.md) e [`.agents/skills/`](.agents/skills/) |
| Endpoints `/api/v1/products` | ⏳ Especificados no PRD, não implementados |
| Migrações Flyway | ⏳ Nenhuma migração criada |
| Testes unitários de produto | ⏳ Inexistentes; a suíte unitária retorna `SKIP` |
| Quality gates (JaCoCo, PIT, ArchUnit) | ⏳ Planejados, não configurados |
| Observabilidade (Datadog) e testes de carga (k6) | ⏳ Planejados; os scripts em `performance/k6/` estão vazios |

## Stack

| Componente | Versão / escolha |
|---|---|
| Linguagem | Java 27 |
| Framework | Spring Boot 4.1.2 (Spring Web MVC) |
| Persistência | Spring JDBC com SQL explícito; sem JPA ([ADR-0001](docs/architecture/adr/0001-architecture-principles.md)) |
| Banco de dados | PostgreSQL, com esquema versionado por Flyway |
| Testes | JUnit Jupiter, Surefire (`*Test`) e Failsafe (`*IT`), Testcontainers com PostgreSQL 18.2 fixado por digest |
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

O `verify.sh` termina com um resumo por etapa (`PASS`, `FAIL`, `SKIP` ou `NOT RUN`). No estado atual, sem testes unitários, a etapa unitária retorna `SKIP` e o resultado agregado é **PARCIAL**. Isso é esperado e **não** equivale a aprovação. Detalhes, códigos de saída e diagnóstico estão no [guia de testes](docs/how-to/run-tests.md).

## Harness de engenharia

Scripts versionados em `scripts/`, preferidos a comandos Maven avulsos por pessoas e agentes:

| Script | Responsabilidade |
|---|---|
| `scripts/setup.sh` | Inspecionar ambiente, versões e Docker |
| `scripts/build.sh` | Compilar com o Maven Wrapper |
| `scripts/test-unit.sh` | Executar somente `*Test.java` (Surefire) |
| `scripts/test-integration.sh` | Executar somente `*IT.java` (Failsafe) com Testcontainers |
| `scripts/verify.sh` | Orquestrar build, unitários e integração |
| `scripts/guard-branch.sh` | Bloquear operações de entrega em `develop`, `main` ou `master` |
| `scripts/tests/` | Testes do próprio harness |

`SKIP_INTEGRATION=1 bash scripts/verify.sh` omite a integração e produz resultado **parcial**. Use apenas com justificativa comunicada. As regras completas estão no [AGENTS.md, seção 7](AGENTS.md#7-harness-local-de-engenharia).

## Desenvolvimento com agentes de IA

A configuração é **agnóstica de provider**: funciona com Codex, Claude Code, GitHub Copilot, Devin ou qualquer agente que leia arquivos do repositório.

- **[`AGENTS.md`](AGENTS.md)** é o ponto de entrada: stack, regras arquiteturais, fluxo de trabalho, harness, segurança, Git e formato obrigatório de relatório.
- **[`.agents/skills/`](.agents/skills/)** reúne procedimentos especializados no formato aberto [Agent Skills](https://agentskills.io/specification), carregados sob demanda. O catálogo completo está no [AGENTS.md, seção 3](AGENTS.md#catálogo-de-skills).

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
├── AGENTS.md                  # instruções para agentes de IA
├── .agents/skills/            # skills de agente (SKILL.md)
├── docs/
│   ├── product/               # PRD
│   ├── architecture/          # ADRs, packages e regras de dependência
│   ├── engineering/           # Definition of Done
│   ├── features/              # catálogo e template de especificação
│   ├── how-to/                # guias operacionais
│   ├── ai/                    # registros de trabalho com IA
│   └── experiments/           # protocolos de experimentos
├── experiments/               # manifests, prompts e resultados
├── infrastructure/docker/     # Docker Compose (ainda vazio)
├── performance/k6/            # testes de carga (ainda vazios)
├── scripts/                   # harness local
└── src/                       # código e testes Java
```

## Documentação

**Produto e escopo**
- [PRD-001 — Product Catalog API](docs/product/prd.md): requisitos, contrato HTTP e critérios BDD
- [Catálogo de features](docs/features/README.md) e [template de especificação](docs/features/TEMPLATE.md)

**Arquitetura**
- [ADR-0001 — Princípios de arquitetura](docs/architecture/adr/0001-architecture-principles.md)
- [Convenções de packages](docs/architecture/package-conventions.md)
- [Regras de dependência](docs/architecture/dependency-rules.md)

**Engenharia**
- [Definition of Done](docs/engineering/definition-of-done.md)
- [Executar e diagnosticar testes](docs/how-to/run-tests.md)

**Agentes de IA**
- [AGENTS.md](AGENTS.md)
- [Skill feature-delivery](.agents/skills/feature-delivery/SKILL.md) (entrega funcional)
- [Skill project-documentation](.agents/skills/project-documentation/SKILL.md) (documentação)

## Contribuição

- Trabalhe em branches `feature/*`, `fix/*` ou `experiment/*`; a integração ocorre em `develop`.
- Commits seguem [Conventional Commits](https://www.conventionalcommits.org/), em inglês e no imperativo, por exemplo `feat(product): add product creation endpoint`.
- Antes de abrir um pull request, execute `bash scripts/guard-branch.sh` e `bash scripts/verify.sh` e confira a [Definition of Done](docs/engineering/definition-of-done.md).

Documentação em português brasileiro; código, identificadores, branches e commits em inglês. As regras completas estão no [AGENTS.md, seção 9](AGENTS.md#9-git-e-versionamento).

## Licença

Ainda não definida. O `pom.xml` não declara licença e não há arquivo `LICENSE` no repositório.
