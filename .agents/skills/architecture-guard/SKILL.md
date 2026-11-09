---
name: architecture-guard
description: >-
  Verifica se código novo ou alterado respeita a arquitetura Feature-Based, as
  convenções de packages e as regras de dependência do Java AI Engineering Lab, e
  identifica quando uma mudança exige decisão arquitetural (ADR). Use ao planejar,
  implementar ou revisar código Java. Não use para aprovar ADRs nem alterar padrões
  aprovados unilateralmente.
---

# Architecture Guard

## Fontes de verdade

- [ADR-0001 — Princípios de arquitetura](../../../docs/architecture/adr/0001-architecture-principles.md)
- [Convenções de packages](../../../docs/architecture/package-conventions.md)
- [Regras de dependência](../../../docs/architecture/dependency-rules.md)

Esta skill resume os pontos de verificação; em divergência, os documentos prevalecem.

## Verificações

1. **Localização** — O código de negócio está em `io.github.wesleyosantos91.catalog.feature.<feature>`; `shared` contém apenas componentes genuinamente transversais.
2. **Direção das dependências** — `api → service → domain`, `service → persistence`, `persistence → domain` quando necessário. Nenhuma dependência no sentido inverso nem ciclo.
3. **Domain puro** — Sem imports de Spring MVC, Spring JDBC, DTOs HTTP, persistência ou mensageria.
4. **Controllers finos** — Sem SQL, acesso direto a repository, regra de negócio ou coordenação transacional de múltiplas operações.
5. **Persistence** — SQL explícito com `JdbcClient` ou `JdbcTemplate`; sem JPA; sem decisão de negócio.
6. **Entre features** — Nenhum acesso ao repository de outra feature; comunicação por contrato explícito.
7. **YAGNI** — Nenhum package vazio, interface com implementação única sem motivo, nem Ports, Use Cases ou Adapters por padrão.

## Verificação prática

Até a configuração do ArchUnit, a verificação é por revisão. Um auxílio é procurar imports proibidos, por exemplo:

```bash
grep -rnE "import org\.springframework\.(web|jdbc)" src/main/java --include=*.java | grep "/domain/"
```

Ausência de resultado nesse comando não prova conformidade total; declare a verificação como revisão manual assistida, não como validação automática.

## Quando parar

Se a solução exigir violar uma regra, introduzir JPA, nova biblioteca estrutural ou mudar fronteiras, pare: descreva a contradição, alternativas e trade-offs e solicite decisão técnica. Um novo ADR só é redigido com autorização e nunca é aceito pelo agente.
