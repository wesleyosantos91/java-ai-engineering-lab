
# Convenções de packages

## Objetivo

Definir a organização do código Java utilizando
arquitetura Feature-Based pragmática.

Package base:
`io.github.wesleyosantos91.catalog`

## Princípios

- Organizar o código prioritariamente por funcionalidade.
- Manter componentes relacionados próximos.
- Criar somente packages necessários à funcionalidade.
- Evitar abstrações sem justificativa técnica.
- Manter regras de negócio independentes de infraestrutura.
- Não utilizar Ports, Use Cases ou Adapters por padrão.

## Estrutura de referência

```text
catalog/
├── JavaAiEngineeringLabApplication.java
├── feature/
│   └── product/
│       ├── api/
│       │   ├── rest/v1/
│       │   │   ├── request/
│       │   │   ├── response/
│       │   │   └── mapper/
│       │   ├── grpc/
│       │   └── webhook/
│       ├── messaging/
│       │   ├── kafka/
│       │   │   ├── consumer/
│       │   │   ├── producer/
│       │   │   └── contract/
│       │   ├── sqs/
│       │   ├── sns/
│       │   └── rabbitmq/
│       ├── client/
│       │   ├── http/
│       │   ├── grpc/
│       │   └── webhook/
│       ├── service/
│       ├── domain/
│       │   ├── entity/
│       │   ├── valueobject/
│       │   ├── policy/
│       │   ├── event/
│       │   └── exception/
│       ├── persistence/
│       │   ├── repository/
│       │   └── mapper/
│       ├── scheduler/
│       └── batch/
│           ├── reader/
│           ├── processor/
│           └── writer/
└── shared/
    ├── exception/
    ├── validation/
    ├── observability/
    └── configuration/
```

## Responsabilidades

### api
Recebe requisições externas e adapta dados
de transporte para operações da aplicação.

Não deve conter SQL ou regras de negócio.

### messaging
Implementa integrações assíncronas como
Kafka, SQS, SNS e RabbitMQ.

Consumers recebem eventos.
Producers e publishers enviam mensagens.

### client
Encapsula chamadas a sistemas externos,
incluindo HTTP, gRPC e webhooks de saída.

### service
Coordena operações, transações, persistência
e integrações.

Não deve concentrar invariantes que pertençam
naturalmente às entidades do domínio.

### domain
Contém entidades, value objects, invariantes,
eventos e regras de negócio puras.

Não deve depender de Spring, JDBC, HTTP
ou bibliotecas de mensageria.

### persistence
Implementa acesso ao PostgreSQL por meio
de Spring JDBC e SQL explícito.

Pode utilizar JdbcClient, JdbcTemplate e
mapeadores de resultados.

Não utilizar JPA por padrão.

### scheduler
Implementa gatilhos e execuções agendadas.

### batch
Agrupa leitura, processamento e escrita
em operações de lote, quando necessário.

### shared
Contém componentes genuinamente transversais.

Não deve se tornar um depósito de classes
que não possuem responsabilidade clara.

## Evolução

Esta árvore representa possibilidades futuras.

Não criar packages vazios antecipadamente.

Novos componentes devem respeitar estas
convenções ou justificar uma exceção por ADR.
