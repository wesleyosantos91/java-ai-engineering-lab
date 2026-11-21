# ADR-0005: Seed público e kit só de configuração

- **Status:** Proposta
- **Data:** 2026-11-21
- **Responsável pela decisão:** Wesley Oliveira Santos
- **Substitui:** —
- **Substituído por:** —
- **Relacionados:** [ADR-0002](0002-multi-provider-agent-context.md), [ADR-0004](0004-ai-first-reference-repository.md), [guia de adoção](../../how-to/adopt-in-new-repository.md)

## Contexto

A primeira versão do exportador `scripts/agents/export-kit.sh` copiava, além da configuração AI-First, o `pom.xml`, o Maven Wrapper e classes de teste para a raiz do destino, e gerava `.kit` para mesclar com o projeto existente. Três fatos mudaram isso:

- Os projetos têm um layout fixo: a configuração fica na raiz, o projeto Maven em `app/` (`app/pom.xml`), e outros diretórios (`infra/`, `tests/`) são consumidos por pipelines.
- O kit deve colocar **somente a configuração AI-First**, sem alterar o projeto existente.
- `.github/` pertence ao time de DevOps e já vem configurado; agentes não o alteram.

Além disso, quem começa um projeto do zero quer um ponto de partida pronto, sem negócio, em que o time de negócio escreva o PRD antes de qualquer código e saiba exatamente o que lhe cabe preencher.

## Decisão

1. **Layout:** a configuração AI-First fica na raiz e vale para o repositório inteiro ([layout do repositório](../repository-layout.md)). O projeto Maven fica sempre em `app/`. O harness o localiza pelo arquivo `.harness` (`APP_DIR`), que neste repositório de referência é `.`.
2. **Kit só de configuração** (modo padrão do exportador): grava apenas na raiz e recusa qualquer arquivo sob `app/`, `infra/`, `tests/` ou `.github/`. Detecta o pacote, a classe principal e a stack do app por leitura. Os quality gates ficam opcionais (`QUALITY_GATES=optional`: gate não configurado no pom é SKIP, não PASS) até a configuração do `app/pom.xml` descrita em `docs/how-to/enable-quality-gates.md`.
3. **`.github/`** não é exportado e não é alterado por agentes. A regra está no AGENTS.md, há um `deny` de `Edit`/`Write` no Claude Code (verificado pelo `check-config`) e um item bloqueante na skill `code-review`.
4. Publicar um repositório público, marcado como *GitHub Template*, chamado `java-ai-first-seed`: o chassi de contexto (agentes, skills, harness, quality gates, documentação de engenharia e PRD guiado) com `app/` compilável e gates obrigatórios, `infra/` e `tests/`, sem regra de negócio e sem `.github/`.
5. O seed é **artefato derivado**: este repositório continua a fonte da verdade, e o seed só é alterado regenerando-o com `bash scripts/agents/export-kit.sh <destino> --seed`. Correções feitas direto no seed são perdidas na próxima regeneração.
6. O seed usa nomes neutros e fixos (pacote `com.example.seed`, classe `SeedApplication`, artifactId `java-ai-first-seed`). O projeto criado a partir do template os troca com `bash scripts/agents/init-project.sh`, que só executa sobre um seed ainda não inicializado e com working tree limpa.
7. O template de PRD (`docs/product/TEMPLATE.md`) indica, por seção, quem preenche (Negócio, Engenharia ou Ambos) e se é obrigatória, com campos `[PREENCHER-NEGÓCIO: ...]` e `[PREENCHER-ENGENHARIA: ...]`. `scripts/product/check-prd.sh` lista as pendências por responsável e rejeita um PRD com Status Aprovado e campos pendentes; `scripts/agents/check-config.sh` aplica essa rejeição.
8. O seed é publicado sob Apache-2.0, a mesma licença deste repositório; projetos derivados escolhem a própria.

## Alternativas consideradas

- **Kit injetando pom e testes com mesclagem `.kit`** (primeira versão): não adotada. Altera o projeto existente e exige mesclagem manual de build.
- **AGENTS.md e skills dentro de `app/`:** não adotada. Os agentes também alteram `infra/`, `tests/` e a documentação; as regras precisam valer para o repositório inteiro.
- **Bloquear `.github/` no pre-commit:** não adotada. Também barraria os commits do time de DevOps.

- **Somente o exportador:** não adotada. Exige acesso a este repositório e uma mesclagem manual com um projeto do Initializr antes do primeiro build.
- **Seed sem script de inicialização:** não adotada. A renomeação manual de pacote, classe e identidade Maven deixa resíduos que o harness não detectaria em todos os arquivos.
- **PRD separado para negócio e engenharia, ou formulário de issue:** não adotada. Duplica a fonte do contrato; um único PRD com responsáveis explícitos mantém o contrato num só lugar.
- **Manter o seed por edição direta:** não adotada. Os dois repositórios divergiriam sem verificação.

## Consequências positivas

- Projeto existente recebe a configuração sem nenhuma mudança no app, na infraestrutura ou nos workflows.
- Novo projeto parte de um repositório que compila e passa no harness (resultado PARCIAL esperado, sem código de negócio).
- O time de negócio vê o que lhe cabe no PRD e consegue conferir o andamento sem conhecer o código.
- A regeneração e a inicialização são verificadas por `scripts/harness-tests/export-kit.sh`.

## Consequências negativas

- Num projeto existente, os gates ficam opcionais até alguém configurar o `app/pom.xml`, e o `verify.sh` mostra PARCIAL enquanto isso.
- Codex e Devin não têm bloqueio por caminho para `.github/`: dependem da regra e da revisão.
- A sincronização do seed com este repositório é manual (regenerar e publicar); não há automação por CI.
- Projetos já criados a partir do seed não recebem correções posteriores do chassi automaticamente.

## Validação

- `bash scripts/harness-tests/export-kit.sh`: exporta só a configuração para um projeto com `app/`, `infra/` e `.github/` e verifica por hash que nada neles mudou; exporta o seed, verifica a ausência de resíduos do produto, inicializa um projeto com `init-project.sh` e executa o harness nele.
- `bash scripts/harness-tests/harness.sh`: `APP_DIR=app`, gate não configurado como SKIP (`optional`) e FAIL (`required`), e `.harness` inválido.
- `bash scripts/harness-tests/agent-config.sh`: comprova que `check-config.sh` aceita PRD em elaboração e rejeita PRD aprovado com pendências, a ausência do `deny` de `.github/` e um `APP_DIR` diferente de `app` em projeto.
- No seed publicado: `bash scripts/verify.sh` com Docker antes de cada publicação.

## Revisão da decisão

Rever se a divergência entre o seed e este repositório se tornar frequente (motivo para sincronização por CI), se surgirem seeds para outras stacks ou se o time de negócio preferir outra forma de registrar requisitos.
