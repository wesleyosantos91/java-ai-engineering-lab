
# Regras de dependência arquitetural

## Objetivo

Estabelecer as direções permitidas de dependência
entre componentes da arquitetura Feature-Based.

## Dependências permitidas

- api → service
- messaging.consumer → service
- scheduler → service
- service → domain
- service → persistence
- service → client
- service → messaging.producer
- persistence → domain, quando necessário

## Restrições

### Domínio

O domínio não deve depender de:

- Spring MVC
- Spring JDBC
- Controllers ou DTOs HTTP
- Consumers e producers
- Clientes de infraestrutura
- Classes de persistência

### API

Dentro da feature, `api` depende **somente** de `service`:
requests, responses e handlers HTTP usam os tipos
do service (comandos, resultados e exceções),
nunca classes de `domain` ou `persistence`.
O service traduz as exceções do domínio
(decisão de 2026-11-20, registrada no ADR-0003).

Controllers não devem:

- Executar consultas SQL.
- Acessar diretamente repositories.
- Implementar regras de negócio.
- Coordenar transações de múltiplas operações.

### Persistência

Repositories devem:

- Encapsular SQL e mapeamento de resultados.
- Respeitar contratos de acesso a dados.
- Evitar decisões de negócio.
- Preservar a integridade transacional.

### Integrações

Consumers devem delegar operações de negócio.

Producers não devem depender de controllers
ou de services que os utilizam.

### Comunicação entre features

Uma feature não deve acessar diretamente
o repository de outra.

A comunicação entre features deve utilizar
um contrato explícito e documentado.

Dependências cíclicas não são permitidas.

## Exceções

Desvios precisam de justificativa técnica.

Alterações relevantes nas fronteiras devem
ser registradas em ADR.

## Validação

As regras são automatizadas com ArchUnit em
`src/test/java/io/github/wesleyosantos91/catalog/architecture/ArchitectureTest.java`
e executadas por `bash scripts/test/architecture.sh`
(lista de regras no [guia de testes](../how-to/run-tests.md#archunit)).
O que não tem regra automatizada continua
verificado por revisão de código.

Não declarar uma regra como automaticamente
protegida antes da implementação do teste.
