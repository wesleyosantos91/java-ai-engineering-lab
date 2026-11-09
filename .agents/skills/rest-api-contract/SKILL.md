---
name: rest-api-contract
description: >-
  Implementa e revisa endpoints REST do Java AI Engineering Lab em conformidade com o
  contrato HTTP do PRD, incluindo rotas versionadas, status, representação JSON,
  paginação e erros ProblemDetail (RFC 9457). Use ao criar ou alterar controller,
  request, response ou tratamento de erros HTTP. Não use para alterar o contrato
  aprovado sem autorização.
---

# REST API Contract

## Fonte de verdade

O [PRD, seções 5 e 6](../../../docs/product/prd.md) define rotas, status, representação e erros. O código implementa o contrato; não o redefine. Divergência entre necessidade técnica e contrato é reportada como pendência.

## Regras de implementação

1. **Rotas** — Versionadas em `/api/v1/...`; controllers em `feature/<feature>/api/rest/v1/`, com `request/`, `response/` e `mapper/` somente quando necessários.
2. **Status** — Exatamente os do contrato. Exemplos: `201 Created` na criação, `204 No Content` na exclusão, `404` para recurso inexistente, `409` para conflito, `400` para entrada ou paginação inválida.
3. **Representação** — DTOs como `record`; nunca exponha entidades de domínio ou linhas de banco diretamente. Respeite a rejeição de campos desconhecidos e as normalizações definidas no PRD.
4. **Validação** — Bean Validation na borda para formato; invariantes de negócio no `domain`.
5. **Erros** — `ProblemDetail` com `application/problem+json` e campos `type`, `title`, `status`, `detail` e `instance` conforme aplicável. Centralize a tradução em um `@RestControllerAdvice`. Não exponha stack traces, SQL ou dados sensíveis.
6. **Controller fino** — Delegue ao `service`; sem SQL, repository ou regra de negócio.

## Testes de contrato

Para cada endpoint, cubra pelo menos o status de sucesso, o corpo e os headers relevantes (por exemplo `Location` e `Content-Type`), cada erro previsto com o corpo `ProblemDetail` e os cenários BDD correspondentes.

## Mudanças de contrato

Mudança incompatível de rota, status, campo ou semântica é breaking change: exige autorização, atualização do PRD pelo processo próprio, nova versão quando aplicável e commit com `!`. Não faça essa mudança silenciosamente.

## Documentação

Atualize a referência de API com a [skill project-documentation](../project-documentation/SKILL.md) quando o comportamento implementado mudar.
