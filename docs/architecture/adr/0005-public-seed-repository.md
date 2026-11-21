# ADR-0005: Seed público e kit só de configuração

- **Status:** Proposta
- **Data:** 2026-11-21
- **Responsável pela decisão:** Wesley Oliveira Santos
- **Substitui:** —
- **Substituído por:** —
- **Relacionados:** [ADR-0002](0002-multi-provider-agent-context.md), [ADR-0003](0003-test-suites-and-quality-gates.md), [layout do repositório](../repository-layout.md), [guia de adoção](../../how-to/adopt-in-new-repository.md)

## Contexto

Times querem aplicar a configuração AI-First deste repositório (instruções e skills dos agentes, harness, PRD guiado, ADRs) em dois cenários:

- **Projeto existente**, com layout fixo: configuração na raiz, projeto Maven em `app/` (`app/pom.xml`) e outros diretórios (`infra/`, `tests/`) consumidos por pipelines. O projeto não pode ser alterado pela aplicação da configuração, e `.github/` pertence ao time de DevOps.
- **Projeto novo**, sem nada de negócio, em que o time de negócio escreve o PRD antes de qualquer código.

Nos dois casos, o projeto resultante precisa ser autossuficiente (sem depender deste repositório, do seed nem das ferramentas de exportação) e deixar explícito, com as seções prontas, o que cada responsável preenche.

## Decisão

1. **Layout:** a configuração AI-First fica na raiz e vale para o repositório inteiro ([layout do repositório](../repository-layout.md)). O projeto Maven fica sempre em `app/`. O harness lê o `.harness` (`APP_DIR`, `QUALITY_GATES`, `REPOSITORY_ROLE`). Só um repositório com `REPOSITORY_ROLE=reference`, como este, usa outro `APP_DIR`; o `check-config` rejeita isso em projetos.
2. **Kit só de configuração** (`scripts/agents/export-kit.sh <destino>`): grava apenas na raiz e recusa qualquer arquivo sob `app/`, `infra/`, `tests/` ou `.github/`. Detecta, só por leitura, o pacote, a classe principal, o Java, o Spring Boot e os starters do app. Os quality gates ficam opcionais (`QUALITY_GATES=optional`: gate não configurado no pom é SKIP, não PASS) até a configuração do `app/pom.xml`.
3. **Projeto autossuficiente:** as ferramentas do kit (exportador e seu teste) não vão para o projeto. Os documentos exportados não citam este repositório nem o seed, e o guia de quality gates traz os blocos de pom e as classes de teste já com o pacote do projeto.
4. **Seções prontas para preencher:** PRD com responsável e obrigatoriedade por seção; `AGENTS.md` §1 (propósito) e §2 (stack detectada, persistência a completar); README do projeto; seção "Revisão neste projeto" nos ADRs 0001 a 0003, que entram como Proposta; licença no `CONTRIBUTING.md`. Os campos são `[PREENCHER-NEGÓCIO: ...]` ou `[PREENCHER-ENGENHARIA: ...]`, listados por `scripts/agents/list-pending.sh`. O `scripts/product/check-prd.sh` rejeita um PRD Aprovado com pendências.
5. **`.github/`** não é exportado e não é alterado por agentes: regra no AGENTS.md, `deny` de `Edit`/`Write` no Claude Code (verificado pelo `check-config`) e item bloqueante na skill `code-review`.
6. **Seed público** `java-ai-first-seed` (*GitHub Template*): a configuração com `app/` compilável e gates obrigatórios, `infra/` e `tests/`, sem negócio e sem `.github/`. É artefato derivado: só muda por regeneração (`export-kit.sh --seed`) publicada por pull request. Correções feitas direto no seed se perdem.
7. O seed usa nomes neutros (`com.example.seed`, `SeedApplication`, `java-ai-first-seed`). `scripts/agents/init-project.sh` os troca, só sobre um seed não inicializado e com working tree limpa, e **se remove ao final** (junto com `scripts/lib/rename.sh`): o projeto criado não depende do seed.
8. O seed é publicado sob Apache-2.0, a licença deste repositório; projetos derivados escolhem a própria.

## Alternativas consideradas

- **Kit copiando `pom.xml`, Maven Wrapper e testes, com mesclagem `.kit`:** não adotada. Altera o projeto existente e exige mesclagem manual de build.
- **AGENTS.md e skills dentro de `app/`:** não adotada. Os agentes também alteram `infra/`, `tests/` e a documentação; as regras precisam valer para o repositório inteiro.
- **Detectar o repositório de referência por um arquivo dele (por exemplo, um ADR):** não adotada. Acopla o harness a um documento específico; o papel é declarado no `.harness`.
- **Guia de quality gates apontando para o seed:** não adotada. O projeto dependeria de um repositório externo; os blocos são gerados no próprio guia.
- **Manter `init-project.sh` no projeto após o uso:** não adotada. É código morto e acoplado ao seed.
- **PRD separado para negócio e engenharia, ou formulário de issue:** não adotada. Duplica a fonte do contrato.
- **Bloquear `.github/` no pre-commit:** não adotada. Também barraria os commits do time de DevOps.

## Consequências positivas

- Projeto existente recebe a configuração sem nenhuma mudança no app, na infraestrutura ou nos workflows.
- O projeto resultante não depende deste repositório nem do seed, e cada responsável sabe o que preencher, em seções já estruturadas.
- Projeto novo parte de um repositório que compila e passa no harness (resultado PARCIAL esperado, sem código de negócio).

## Consequências negativas

- Num projeto existente, os gates ficam opcionais até alguém configurar o `app/pom.xml`; o `verify.sh` mostra PARCIAL enquanto isso.
- Codex e Devin não têm bloqueio por caminho para `.github/`: dependem da regra e da revisão.
- A sincronização do seed com este repositório é manual (regenerar e publicar por pull request); projetos já criados não recebem correções do chassi automaticamente.

## Validação

- `bash scripts/harness-tests/export-kit.sh`: exporta só a configuração para um projeto com `app/`, `infra/` e `.github/` e verifica por hash que nada neles mudou, que as ferramentas do kit não foram copiadas, que não há referência a este repositório ou ao seed e que as seções prontas existem (AGENTS.md, README, ADRs, blocos de quality gates com o pacote do projeto). Exporta o seed, inicializa um projeto com `init-project.sh`, verifica a remoção do script e executa o harness nele.
- `bash scripts/harness-tests/harness.sh`: `APP_DIR=app`, gate não configurado como SKIP (`optional`) e FAIL (`required`), e `.harness` inválido.
- `bash scripts/harness-tests/agent-config.sh`: PRD em elaboração aceito e Aprovado com pendências rejeitado; ausência do `deny` de `.github/`; `APP_DIR` diferente de `app` sem `REPOSITORY_ROLE=reference`.
- No seed publicado: `bash scripts/verify.sh` com Docker antes de cada publicação.

## Revisão da decisão

Rever se a divergência entre o seed e este repositório se tornar frequente (motivo para sincronização por CI), se surgirem seeds para outras stacks ou se o time de negócio preferir outra forma de registrar requisitos.
