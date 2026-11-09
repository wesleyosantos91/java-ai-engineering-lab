---
name: code-simplification
description: >-
  Reduz complexidade acidental de código Java existente sem alterar comportamento,
  aplicando KISS, YAGNI e SOLID de forma pragmática. Use na fase Refactor do TDD, após
  uma feature funcionar ou quando uma revisão apontar duplicação ou abstração
  desnecessária. Não use para mudar comportamento, contratos ou arquitetura aprovada.
---

# Code Simplification

## Objetivo e limites

Deixar o código mais simples de ler e manter, preservando o comportamento observável. Refatoração exige testes verdes antes e depois; sem cobertura do comportamento afetado, escreva o teste primeiro.

## O que procurar

- Abstrações sem segunda implementação real: interfaces únicas, factories e camadas especulativas. O projeto não adota Ports, Use Cases ou Adapters por padrão.
- Duplicação real de regra de negócio, não apenas semelhança visual.
- Métodos longos com vários níveis de abstração; condicionais aninhadas que podem virar retorno antecipado.
- Nomes que não expressam a intenção do domínio.
- Lógica de negócio fora do `domain` ou SQL fora da `persistence`.
- Código morto, parâmetros não usados e comentários que repetem o código.
- Recursos modernos de Java que simplificam sem obscurecer, como `record`, `switch` com pattern matching e `sealed`, quando adequados.

## Procedimento

1. Execute os testes do escopo e confirme PASS antes de começar.
2. Faça uma transformação pequena por vez.
3. Execute os testes após cada transformação.
4. Revise o diff: deve haver apenas mudança estrutural, sem mudança funcional.
5. Use commits `refactor(<scope>): ...` separados de mudanças funcionais, quando houver autorização para commit.

## Limites

- Não introduza dependências para simplificar.
- Não reorganize packages além do previsto nas [convenções](../../../docs/architecture/package-conventions.md).
- Simplificação que mude fronteiras arquiteturais exige decisão técnica, conforme a [skill architecture-guard](../architecture-guard/SKILL.md).
