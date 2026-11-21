---
name: systematic-debugging
description: >-
  Investiga defeitos, testes falhando, erros de build ou comportamento inesperado pela
  causa raiz antes de propor correção. Use sempre que uma verificação retornar FAIL,
  um bug for reportado ou um comportamento divergir do contrato. Não use para
  implementar funcionalidade nova.
---

# Systematic Debugging

## Princípio

Nenhuma correção sem causa raiz identificada e evidenciada. Tentativas aleatórias escondem o defeito e geram regressões.

## Fases

1. **Reproduzir** — Obtenha uma reprodução determinística: comando, teste ou requisição. Registre a saída real. Sem reprodução, colete mais dados antes de corrigir.
2. **Isolar** — Leia a mensagem de erro e o stack trace completos. Reduza o escopo: qual camada (`api`, `service`, `domain`, `persistence`, configuração, ambiente ou Docker), qual commit ou alteração recente, qual dado de entrada.
3. **Formular hipótese** — Escreva uma hipótese única e falsificável: "falha porque X; se correto, Y acontecerá".
4. **Confirmar** — Teste a hipótese com a menor intervenção possível: log temporário, teste focado ou consulta. Descarte hipóteses refutadas e registre-as.
5. **Corrigir** — Escreva primeiro um teste que reproduz o defeito (Red) e depois a correção mínima (Green), conforme a [skill tdd-workflow](../tdd-workflow/SKILL.md).
6. **Verificar** — Execute o teste focado e depois `bash scripts/verify.sh`. Remova instrumentação temporária.

## Regra das três tentativas

Após três correções fracassadas para o mesmo problema, pare. O problema provavelmente é de desenho ou de entendimento do contrato: apresente as evidências ao usuário e proponha revisão técnica em vez de uma quarta tentativa.

## Falhas de ambiente

Docker indisponível, porta ocupada ou versão de Java incorreta são impedimentos de ambiente. Use `bash scripts/setup.sh` para diagnóstico e registre a verificação afetada como NOT RUN, sem omissão silenciosa.

## Proibições

- Desabilitar o teste, capturar e ignorar exceções ou alterar o contrato para "resolver" a falha.
- Declarar a correção sem executar a reprodução original novamente.
- Apagar o histórico do FAIL; ele permanece registrado junto da correção.

## Relato

Inclua sintoma, reprodução, causa raiz, evidência, correção, teste de regressão e verificações executadas.
