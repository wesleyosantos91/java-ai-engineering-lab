# ADR-0004: Repositório de referência AI-First

- **Status:** Proposta
- **Data:** 2026-11-20
- **Responsável pela decisão:** Wesley Oliveira Santos
- **Substitui:** [ADR-0001](0001-architecture-principles.md), parcialmente: apenas o objetivo de comparação controlada entre AI-Assisted e AI-First (Contexto e item "Comparar abordagens com critérios equivalentes" da seção AI-First)
- **Substituído por:** —
- **Relacionados:** [ADR-0002](0002-multi-provider-agent-context.md), [ADR-0003](0003-test-suites-and-quality-gates.md), [PRD-001 versão 1.1](../../product/prd.md)

## Contexto

O repositório nasceu como laboratório para comparar, por experimentos controlados, o desenvolvimento AI-Assisted e o AI-First (PRD 1.0, seções 1, 2 e 11; ADR-0001). A construção da fundação mostrou que o valor principal está na própria configuração: instruções versionadas, skills, contexto em camadas, harness que impede falso PASS, PRD e ADRs como contrato, e adaptadores para Codex, Claude Code e Devin.

O responsável decidiu reorientar o objetivo: o repositório passa a ser um **exemplo de referência** de como configurar um projeto AI-First com boas práticas. A estrutura de experimentos (`experiments/` e a skill `experiment-protocol`) não tinha nenhum experimento registrado e deixou de ter propósito.

## Decisão

1. O repositório é uma referência de configuração AI-First para projetos Java. A Product Catalog API (PRD-001) é a aplicação-exemplo que demonstra as práticas.
2. Toda prática adotada precisa ter documentação (o quê, por quê e como evoluir) e verificação no harness (`scripts/`), ou ter a ausência de verificação declarada como limitação.
3. Recursos específicos de um provider de IA só entram com adaptador fino e verificação automatizada (ADR-0002).
4. Remover `experiments/` e a skill `experiment-protocol`, além das regras de experimentação do `AGENTS.md`, do PRD, do workflow de entrega e do catálogo de features.
5. O prefixo de branch `experiment/*` é mantido para spikes e provas de conceito.
6. As demais decisões do ADR-0001 continuam vigentes: stack, arquitetura Feature-Based, persistência, qualidade, observabilidade e medição antes de otimizar.

## Alternativas consideradas

- **Manter o laboratório comparativo:** não adotada por decisão do responsável. O objetivo passa a ser ensinar e demonstrar a configuração, não medir a diferença entre modalidades.
- **Manter `experiments/` vazio "para o futuro":** não adotada. Contraria a regra de não criar estrutura especulativa. Se experimentos voltarem, um novo ADR os reintroduz.
- **Editar o ADR-0001:** não adotada. ADRs aceitos são imutáveis no conteúdo; a substituição parcial fica registrada aqui e no índice.

## Consequências positivas

- Propósito claro para quem chega ao repositório: um modelo a ser copiado e adaptado.
- Menos estrutura sem uso e menos contexto fixo para os agentes.
- Critério objetivo para novas práticas: documentadas e verificáveis.

## Consequências negativas

- Perde-se a capacidade, prevista inicialmente, de comparar modalidades com protocolo formal.
- O PRD precisa de nova versão (1.1), sujeita a aprovação.

## Validação

- `bash scripts/agents/check-config.sh` garante catálogo de skills, links e caminhos de scripts coerentes após a remoção.
- Revisão humana do PRD 1.1 e deste ADR.

## Revisão da decisão

Revisar se o repositório voltar a ser usado para experimentos comparativos ou se passar a servir de template publicado (por exemplo, como GitHub template repository).
