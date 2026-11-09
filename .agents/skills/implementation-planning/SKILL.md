---
name: implementation-planning
description: >-
  Converte uma especificação aprovada em plano técnico com tarefas pequenas, ordenadas
  e verificáveis antes de editar código. Use para mudanças não triviais, features novas,
  correções em vários arquivos ou refatorações. Não use para mudanças triviais nem para
  decidir regras de produto.
---

# Implementation Planning

## Objetivo e limites

Detalhar a fase 4 do [workflow de entrega](../feature-delivery/references/workflow.md) sem substituí-la. O plano obedece ao [ADR-0001](../../../docs/architecture/adr/0001-architecture-principles.md), às [convenções de packages](../../../docs/architecture/package-conventions.md) e às [regras de dependência](../../../docs/architecture/dependency-rules.md). Planejar não autoriza implementar.

## Procedimento

1. Leia a especificação e os arquivos existentes envolvidos; não planeje sobre suposições do código.
2. Mapeie cada critério BDD para os componentes afetados (`api`, `service`, `domain`, `persistence`) e para o teste que o comprovará.
3. Liste somente arquivos e packages necessários, sem packages vazios ou abstrações especulativas.
4. Quebre o trabalho em tarefas pequenas, cada uma com:
   - objetivo e arquivos;
   - teste a escrever primeiro, quando TDD se aplicar;
   - comando de verificação e resultado esperado.
5. Ordene por dependência: migração e domínio antes de service; service antes de api.
6. Identifique riscos (transações, concorrência, migração de dados, contrato HTTP) e decisões que exigem ADR ou aprovação humana.
7. Apresente o plano de forma breve antes de editar.

## Formato sugerido

```markdown
## Plano — FEAT-XXXX
- [ ] T1 — <objetivo> · arquivos: ... · teste: ... · verificação: bash scripts/test-unit.sh
- [ ] T2 — ...
Riscos: ...
Decisões pendentes: ...
```

Para trabalho que atravessa sessões ou providers, persista o plano com a [skill task-state-files](../task-state-files/SKILL.md). Execute com a [skill plan-execution](../plan-execution/SKILL.md).
