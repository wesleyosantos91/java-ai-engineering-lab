# Architecture Decision Records (ADRs)

Registro versionado das decisões arquiteturais do Java AI Engineering Lab. Cada ADR descreve o contexto, a decisão, as alternativas e as consequências, e preserva o histórico mesmo quando a decisão é substituída.

## Índice

| ADR | Título | Status | Data |
|---|---|---|---|
| [0001](0001-architecture-principles.md) | Princípios de arquitetura | Aceita; objetivo de comparação substituído parcialmente pelo 0004 (proposto) | — |
| [0002](0002-multi-provider-agent-context.md) | Contexto de agentes multi-provider | Proposta | 2026-11-20 |
| [0003](0003-test-suites-and-quality-gates.md) | Suítes de teste e quality gates | Proposta | 2026-11-20 |
| [0004](0004-ai-first-reference-repository.md) | Repositório de referência AI-First | Proposta | 2026-11-20 |

## Quando registrar um ADR

Registre um ADR quando a decisão:

- alterar ou complementar a stack, a arquitetura, a persistência ou a organização de packages;
- introduzir, substituir ou remover dependência, framework ou ferramenta relevante;
- mudar metas, escopos ou exclusões dos quality gates;
- alterar a forma como agentes de IA recebem contexto, permissões ou limites de autonomia;
- for difícil de reverter ou afetar mais de uma feature.

Detalhes de implementação de uma única feature ficam em `docs/features/FEAT-XXXX-*/design.md`, não em ADR.

## Ciclo de vida

```text
Proposta → Aceita → (Depreciada | Substituída por ADR-NNNN)
        ↘ Rejeitada
```

| Status | Significado |
|---|---|
| Proposta | Em revisão; não é norma vigente |
| Aceita | Decisão vigente, aprovada por revisão humana |
| Rejeitada | Avaliada e não adotada; mantida como histórico |
| Depreciada | Deixou de valer sem substituição direta |
| Substituída | Outro ADR assumiu a decisão; informe qual |

Regras:

1. **Somente revisão humana** muda o status para Aceita, Rejeitada, Depreciada ou Substituída. Agentes podem redigir ADRs apenas com status Proposta.
2. **ADRs aceitos são imutáveis no conteúdo.** Correções editoriais (links, ortografia) são permitidas. Mudança de decisão exige novo ADR que substitui o anterior. No ADR antigo, só o status e o campo "Substituído por" são atualizados.
3. Um ADR pode **complementar** outro sem substituí-lo; registre a relação no campo "Relacionados".
4. Atualize este índice no mesmo commit que cria o ADR ou altera seu status.

## Numeração e arquivo

- Arquivo `NNNN-kebab-case-title.md` neste diretório, com número sequencial de quatro dígitos e título em inglês.
- Use o maior número existente mais um. Números não são reutilizados, nem de ADRs rejeitados.
- Parta do [TEMPLATE.md](TEMPLATE.md). O conteúdo é em português brasileiro.

## Relação com outros documentos

| Documento | Relação |
|---|---|
| [PRD](../../product/prd.md) | Define *o quê* o produto deve fazer; ADRs definem *como* a solução é estruturada |
| [Convenções de packages](../package-conventions.md) e [regras de dependência](../dependency-rules.md) | Detalham decisões aceitas; não podem contradizê-las |
| [Catálogo de features](../../features/README.md) | Specs referenciam os ADRs que aplicam |
| [AGENTS.md](../../../AGENTS.md) | Resume as decisões vigentes para os agentes |
