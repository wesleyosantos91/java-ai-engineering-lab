---
name: verification-before-completion
description: >-
  Impede declarar uma tarefa pronta, corrigida ou aprovada sem executar as verificações
  pertinentes e apresentar evidência real. Use antes de qualquer relatório final,
  mudança de estado de feature ou pedido de revisão. Aplica-se a código, testes,
  configuração e documentação.
---

# Verification Before Completion

## Princípio

Afirmação sem evidência não é conclusão. Este procedimento operacionaliza a seção 7 do [AGENTS.md](../../../AGENTS.md), a fase 6 do [workflow](../feature-delivery/references/workflow.md) e a [DoD](../../../docs/engineering/definition-of-done.md); em conflito, esses documentos prevalecem.

## Checklist obrigatório

1. Identifique o tipo da alteração e a verificação correspondente:
   - código Java, testes, dependências, build ou configuração: `bash scripts/verify.sh`;
   - somente documentação: `git diff` e `git diff --check`, mais `git diff --cached --check` se houver arquivos preparados.
2. Execute a verificação agora, na revisão atual do código; resultados de execuções anteriores a mudanças não valem.
3. Leia a saída completa: código de saída, testes executados, falhas e avisos relevantes.
4. Classifique cada verificação como PASS, FAIL, SKIP ou NOT RUN.
5. Relacione cada critério de aceitação ao teste ou evidência que o comprova; marque os não comprovados.
6. Revise o diff completo, inclusive arquivos novos, e procure alterações inesperadas.

## Linguagem proibida sem evidência

"Deve funcionar", "provavelmente passa", "pronto", "testado", "aprovado" e "corrigido" só podem ser usados depois da execução que os comprova.

## Regras de interpretação

- SKIP e NOT RUN não equivalem a PASS.
- `SKIP_INTEGRATION=1` produz resultado parcial e precisa de justificativa comunicada.
- Código de saída zero sem testes elegíveis não prova comportamento.
- Quality gates não configurados (JaCoCo, PIT, ArchUnit) não podem ser declarados aprovados.

## Relato final

Use o formato da seção 12 do AGENTS.md, com comandos executados e resultados observados.
