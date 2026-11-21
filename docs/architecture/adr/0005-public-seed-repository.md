# ADR-0005: Seed público derivado deste repositório

- **Status:** Proposta
- **Data:** 2026-11-21
- **Responsável pela decisão:** Wesley Oliveira Santos
- **Substitui:** —
- **Substituído por:** —
- **Relacionados:** [ADR-0002](0002-multi-provider-agent-context.md), [ADR-0004](0004-ai-first-reference-repository.md), [guia de adoção](../../how-to/adopt-in-new-repository.md)

## Contexto

O exportador `scripts/agents/export-kit.sh` leva a configuração AI-First a outro repositório, mas exige clonar este repositório de referência, e o resultado não compila sozinho: falta a aplicação Spring Boot, que o novo projeto precisa trazer (por exemplo, do Spring Initializr) e mesclar. Times que começam um projeto querem um ponto de partida pronto, sem nada de negócio, em que o time de negócio possa escrever o PRD antes de qualquer código e saiba exatamente o que lhe cabe preencher.

## Decisão

1. Publicar um repositório público, marcado como *GitHub Template*, chamado `java-ai-first-seed`: o chassi de contexto (agentes, skills, harness, quality gates, governança, documentação de engenharia e PRD guiado) com uma aplicação mínima compilável e nenhuma regra de negócio.
2. O seed é **artefato derivado**: este repositório continua a fonte da verdade, e o seed só é alterado regenerando-o com `bash scripts/agents/export-kit.sh <destino> --seed`. Correções feitas direto no seed são perdidas na próxima regeneração.
3. O seed usa nomes neutros e fixos (pacote `com.example.seed`, classe `SeedApplication`, artifactId `java-ai-first-seed`). O projeto criado a partir do template os troca com `bash scripts/agents/init-project.sh`, que só executa sobre um seed ainda não inicializado e com working tree limpa.
4. O template de PRD (`docs/product/TEMPLATE.md`) indica, por seção, quem preenche (Negócio, Engenharia ou Ambos) e se é obrigatória, com campos `[PREENCHER-NEGÓCIO: ...]` e `[PREENCHER-ENGENHARIA: ...]`. `scripts/product/check-prd.sh` lista as pendências por responsável e rejeita um PRD com Status Aprovado e campos pendentes; `scripts/agents/check-config.sh` aplica essa rejeição.
5. O seed é publicado sob Apache-2.0, a mesma licença deste repositório; projetos derivados escolhem a própria.

## Alternativas consideradas

- **Somente o exportador:** não adotada. Exige acesso a este repositório e uma mesclagem manual com um projeto do Initializr antes do primeiro build.
- **Seed sem script de inicialização:** não adotada. A renomeação manual de pacote, classe e identidade Maven deixa resíduos que o harness não detectaria em todos os arquivos.
- **PRD separado para negócio e engenharia, ou formulário de issue:** não adotada. Duplica a fonte do contrato; um único PRD com responsáveis explícitos mantém o contrato num só lugar.
- **Manter o seed por edição direta:** não adotada. Os dois repositórios divergiriam sem verificação.

## Consequências positivas

- Novo projeto parte de um repositório que compila e passa no harness (resultado PARCIAL esperado, sem código de negócio).
- O time de negócio vê o que lhe cabe no PRD e consegue conferir o andamento sem conhecer o código.
- A regeneração e a inicialização são verificadas por `scripts/harness-tests/export-kit.sh`.

## Consequências negativas

- A sincronização do seed com este repositório é manual (regenerar e publicar); não há automação por CI.
- Projetos já criados a partir do seed não recebem correções posteriores do chassi automaticamente.

## Validação

- `bash scripts/harness-tests/export-kit.sh`: exporta o seed, verifica a ausência de resíduos do produto, inicializa um projeto com `init-project.sh` e executa o harness nele.
- `bash scripts/harness-tests/agent-config.sh`: comprova que `check-config.sh` aceita PRD em elaboração e rejeita PRD aprovado com pendências.
- No seed publicado: `bash scripts/verify.sh` com Docker antes de cada publicação.

## Revisão da decisão

Rever se a divergência entre o seed e este repositório se tornar frequente (motivo para sincronização por CI), se surgirem seeds para outras stacks ou se o time de negócio preferir outra forma de registrar requisitos.
