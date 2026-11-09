---
name: code-review
description: >-
  Revisa um diff, branch ou pull request do Java AI Engineering Lab quanto a correção,
  aderência ao contrato, arquitetura, testes, segurança e manutenibilidade, produzindo
  achados priorizados e verificáveis. Use ao revisar mudanças próprias antes da entrega
  ou mudanças de terceiros. Não use para implementar as correções sem autorização.
---

# Code Review

## Objetivo e limites

Encontrar defeitos reais antes da integração. A revisão do agente não substitui a revisão humana exigida pelo [catálogo](../../../docs/features/README.md) e pela [DoD](../../../docs/engineering/definition-of-done.md).

## Preparação

1. Obtenha o diff completo (`git diff`, `git diff --cached` ou `git diff develop...HEAD`) e liste os arquivos alterados.
2. Leia a especificação ou o requisito que motivou a mudança.
3. Leia o contexto ao redor das alterações, não apenas as linhas modificadas.

## Checklist

**Correção e contrato**
- O comportamento corresponde ao PRD e aos cenários BDD, incluindo status HTTP e `ProblemDetail`.
- Casos de erro, limites, nulos, concorrência e transações foram tratados.
- Não há funcionalidade fora do escopo.

**Arquitetura** — aplique a [skill architecture-guard](../architecture-guard/SKILL.md).

**Testes**
- Cada comportamento novo tem teste que falharia sem a mudança.
- Asserções verificam o resultado, não apenas a ausência de exceção.
- Nenhum teste foi removido, desabilitado ou enfraquecido.

**Persistência** — aplique a [skill database-migration](../database-migration/SKILL.md) quando houver SQL ou Flyway.

**Segurança** — aplique a [skill security-review](../security-review/SKILL.md) quando houver entrada externa, SQL, logs ou dependências.

**Manutenibilidade**
- Nomes expressivos, ausência de duplicação real e de abstrações especulativas.
- Dependências novas justificadas.

## Formato dos achados

Para cada achado: arquivo e linha, severidade (bloqueante, importante, sugestão), cenário concreto de falha e correção proposta. Ordene do mais grave ao menos grave. Não reporte preferências de estilo como defeitos, e indique quando não houver achados.

## Verificação

Confirme os achados com leitura do código ou teste executado. Diferencie achado confirmado de suspeita.
