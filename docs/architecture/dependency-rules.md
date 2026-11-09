
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

Estas regras serão inicialmente verificadas
por revisão de código.

Posteriormente, serão automatizadas com ArchUnit.

Não declarar uma regra como automaticamente
protegida antes da implementação do teste.
