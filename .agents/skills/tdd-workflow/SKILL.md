---
name: tdd-workflow
description: >-
  Conduz o ciclo Red, Green e Refactor com evidência de cada fase para comportamentos
  Java do Java AI Engineering Lab. Use ao implementar regra de negócio, critério BDD,
  correção de defeito ou contrato HTTP. Não use para alterações exclusivamente
  documentais ou de configuração sem comportamento testável.
---

# TDD Workflow

## Objetivo e limites

Garantir que cada comportamento nasça de um teste que falha pelo motivo certo. O [AGENTS.md](../../../AGENTS.md), seção 6, e a [DoD](../../../docs/engineering/definition-of-done.md) definem as obrigações; esta skill define o procedimento.

## Convenções atuais

- Testes unitários: sufixo exato `*Test.java`, executados pelo Surefire via `bash scripts/test-unit.sh`. Não carregam contexto Spring nem iniciam Testcontainers.
- Testes de integração: sufixo exato `*IT.java` com Testcontainers, executados pelo Failsafe via `bash scripts/test-integration.sh`.
- Os sufixos `*Tests`, `Test*` e `*ITCase` não são executados. Detalhes no [guia de testes](../../../docs/how-to/run-tests.md).
- Nomeie testes pelo comportamento, por exemplo `shouldRejectDuplicateSku`, e use `@DisplayName` com o cenário BDD quando ajudar na rastreabilidade.

## Ciclo

1. **Red** — Escreva um teste para um único comportamento do cenário BDD. Execute-o e confirme que falha pelo motivo esperado (asserção), não por erro de compilação ou configuração. Registre comando e saída resumida.
2. **Green** — Escreva o mínimo de código de produção para o teste passar. Execute o teste e os vizinhos afetados. Registre o resultado.
3. **Refactor** — Melhore nomes, duplicação e estrutura sem mudar comportamento, com os testes verdes antes e depois. Use a [skill code-simplification](../code-simplification/SKILL.md) quando houver complexidade a reduzir.
4. Repita para o próximo comportamento: sucesso, erros, limites e concorrência quando aplicável.

## Escolha do nível de teste

| Comportamento | Nível preferido |
|---|---|
| Invariante de domínio, normalização, validação pura | Unitário do `domain`, sem Spring |
| Coordenação e transação do `service` | Unitário com dublês simples ou integração quando a transação for o comportamento |
| SQL, restrição `UNIQUE`, migração Flyway | Integração com PostgreSQL via Testcontainers |
| Contrato HTTP, status, `ProblemDetail` | Teste web MVC ou integração ponta a ponta |

## Proibições

- Escrever o código antes do teste quando TDD fizer parte da tarefa.
- Ajustar a asserção para aceitar o comportamento errado.
- Desabilitar, remover ou enfraquecer testes para obter sucesso.
- Declarar Red ou Green sem ter executado o teste.
