---
name: experiment-protocol
description: >-
  Define, executa e registra experimentos AI-First e AI-Assisted do Java AI Engineering
  Lab com baseline preservado, requisitos congelados, versões de ferramentas e
  modelos, e métricas observadas. Use ao planejar ou executar um experimento
  comparativo ou ao registrar seus resultados. Não use para alterar requisitos
  congelados nem resultados já registrados.
---

# Experiment Protocol

## Fontes de verdade

- [AGENTS.md, seção 10](../../../AGENTS.md) — regras dos experimentos.
- [PRD, seção 11](../../../docs/product/prd.md) — regras de experimentação com IA.
- [Workflow de entrega, fase 10](../feature-delivery/references/workflow.md).

## Estrutura existente

| Caminho | Uso |
|---|---|
| `docs/experiments/` | Protocolos e análises |
| `experiments/manifests/` | Definição de cada execução: baseline, versões e condições |
| `experiments/prompts/` | Prompts utilizados, versionados como foram executados |
| `experiments/results/` | Resultados brutos e métricas observadas |

As pastas estão vazias; crie arquivos apenas para um experimento real.

## Antes da execução

1. Escreva o protocolo: hipótese, grupos comparados, tarefa, requisitos congelados (versão do PRD ou spec), baseline (commit), métricas e critérios de sucesso.
2. Registre ferramentas e versões: provider, modelo e identificador, cliente, sistema operacional, Java e Maven.
3. Garanta condições equivalentes entre grupos; os testes de avaliação independente não são expostos aos agentes.
4. Obtenha aprovação humana do protocolo.

## Durante a execução

- Uma sessão por execução, sem misturar resultados de sessões diferentes.
- Registre intervenções humanas com momento e motivo.
- Não altere critérios de aceitação nem ferramentas de avaliação.

## Registro de resultados

- Separe sucesso, qualidade, tempo, tokens, custo e intervenção humana.
- Diferencie medido de estimado; dado indisponível é registrado como indisponível.
- Registre falhas e execuções incompletas com o mesmo cuidado que sucessos.
- Resultados registrados não são editados; correções viram registro novo com referência.
