---
name: plan-execution
description: >-
  Executa um plano técnico aprovado tarefa a tarefa, com verificação a cada passo,
  checkpoints e delegação controlada a subagentes quando o cliente suportar. Use após
  implementation-planning, em entregas com várias tarefas. Não use para ampliar escopo,
  pular verificações ou executar operações Git sem autorização.
---

# Plan Execution

## Objetivo e limites

Implementar a menor solução que atenda ao plano e ao contrato, mantendo o progresso auditável. As seções 5, 7 e 8 do [AGENTS.md](../../../AGENTS.md) prevalecem sobre esta skill.

## Procedimento por tarefa

1. Marque a tarefa como em andamento no plano ou no arquivo de estado.
2. Aplique a [skill tdd-workflow](../tdd-workflow/SKILL.md) quando a tarefa envolver comportamento.
3. Implemente somente o necessário para a tarefa.
4. Execute a verificação definida no plano e registre o resultado real: PASS, FAIL, SKIP ou NOT RUN.
5. Em FAIL, pare e aplique a [skill systematic-debugging](../systematic-debugging/SKILL.md); não avance com falha não investigada.
6. Marque a tarefa como concluída apenas com evidência.

## Checkpoints

- A cada grupo de tarefas relacionadas, revise o diff acumulado e apresente um resumo curto.
- Se surgir necessidade fora do plano, pare e proponha a alteração; não a implemente por iniciativa própria.

## Delegação a subagentes

Somente quando o cliente oferecer o recurso e o usuário permitir. Cada subagente recebe uma tarefa isolada, com arquivos, critérios e comando de verificação. O agente principal revisa o resultado antes de aceitá-lo; o relato de um subagente não é evidência até ser verificado. Não delegue em paralelo tarefas que alterem os mesmos arquivos.

## Encerramento

Execute `bash scripts/verify.sh` e siga a [skill verification-before-completion](../verification-before-completion/SKILL.md).
