# Referência da API — Produtos

Contrato implementado de `/api/v1/products`. Fonte normativa: [PRD-001](../../product/prd.md), seções 4 a 7, e [FEAT-0001](../../features/FEAT-0001-create-product/spec.md), decisões D-01 a D-06. Esta página descreve **somente o que está implementado**. Consulta, listagem, atualização e exclusão ainda não existem.

| Operação | Método e caminho | Situação |
|---|---|---|
| Criar | `POST /api/v1/products` | ✅ Implementado (FEAT-0001) |
| Consultar, listar, atualizar, excluir | `GET`, `PUT`, `DELETE` | ⏳ Especificados no PRD, não implementados |

## Criar produto

`POST /api/v1/products` com `Content-Type: application/json`.

### Corpo

| Campo | Tipo | Obrigatório | Regras (após normalização) |
|---|---|---|---|
| `sku` | string | sim | Sem espaços externos e em maiúsculas; 3 a 32 caracteres `A-Z`, `0-9`, `-`, `_`; começa por letra ou número; único |
| `name` | string | sim | Sem espaços externos; 3 a 120 caracteres |
| `description` | string ou `null` | não | Ausente, `null`, vazia ou só com espaços → `null`; senão sem espaços externos e até 500 caracteres |
| `price` | **número** JSON | sim | > 0, ≤ 99999999.99, até 2 casas decimais significativas (`10.500` é aceito como `10.50`; `10.505` é rejeitado); string é rejeitada |

Qualquer outra propriedade, inclusive `id`, `createdAt` e `updatedAt`, é rejeitada com `400`.

### Respostas

| Status | Quando | Corpo |
|---|---|---|
| `201 Created` | Produto criado | Produto completo, com o cabeçalho `Location` (URI absoluta do recurso) |
| `400 Bad Request` | Regra violada, campo desconhecido, tipo inválido, JSON malformado ou corpo ausente | `ProblemDetail` com `code: VALIDATION_FAILED` e, quando identificáveis, `errors` |
| `409 Conflict` | SKU normalizado já existe, inclusive em criações simultâneas | `ProblemDetail` com `code: PRODUCT_SKU_CONFLICT` |

Os erros usam `application/problem+json` ([RFC 9457](https://www.rfc-editor.org/rfc/rfc9457)), com `title`, `status`, `detail`, `instance` e a extensão `code`. O `type` é omitido (equivale a `about:blank`). Nunca contêm SQL, nomes de constraint, classes Java ou stack trace.

### Exemplos

Saídas reais de 2026-11-20, com a aplicação local (`bash ./mvnw spring-boot:test-run`).

Criação válida, com normalização de SKU, nome e descrição:

```http
POST /api/v1/products
Content-Type: application/json

{"sku":" abc-001 ","name":" Caneta azul ","description":"   ","price":12.90}
```

```http
HTTP/1.1 201
Location: http://localhost:8080/api/v1/products/9c0f1b35-7e18-49f0-9c58-54ad6ada0c9a
Content-Type: application/json

{"id":"9c0f1b35-7e18-49f0-9c58-54ad6ada0c9a","sku":"ABC-001","name":"Caneta azul","description":null,"price":12.90,"createdAt":"2026-11-21T00:24:32.937118Z","updatedAt":"2026-11-21T00:24:32.937118Z"}
```

SKU já existente:

```http
HTTP/1.1 409
Content-Type: application/problem+json

{"detail":"A product with SKU 'ABC-001' already exists.","instance":"/api/v1/products","status":409,"title":"Product SKU conflict","code":"PRODUCT_SKU_CONFLICT"}
```

Vários campos inválidos, com todas as violações reportadas de uma vez:

```http
POST /api/v1/products
Content-Type: application/json

{"sku":"x","name":"","price":0}
```

```http
HTTP/1.1 400
Content-Type: application/problem+json

{"detail":"The request body is invalid; see 'errors' for the affected fields.","instance":"/api/v1/products","status":400,"title":"Validation failed","code":"VALIDATION_FAILED","errors":[{"field":"sku","message":"must have 3 to 32 characters (A-Z, 0-9, '-' or '_') and start with a letter or digit"},{"field":"name","message":"must have 3 to 120 characters after trimming"},{"field":"price","message":"must be greater than 0, at most 99999999.99 and have at most 2 decimal places"}]}
```

Propriedade não permitida (`id`):

```http
HTTP/1.1 400
Content-Type: application/problem+json

{"detail":"The request body is invalid; see 'errors' for the affected fields.","instance":"/api/v1/products","status":400,"title":"Validation failed","code":"VALIDATION_FAILED","errors":[{"field":"id","message":"invalid or not allowed value"}]}
```

Erros de leitura do JSON (propriedade desconhecida, tipo inválido) são detectados antes das regras de negócio. Por isso reportam apenas o primeiro campo problemático.

## Persistência

Tabela `product`, criada por `src/main/resources/db/migration/V1__create_product.sql`. As restrições do banco espelham as regras acima: `product_sku_uk` (unicidade, que garante o `409` sob concorrência), `CHECK` de formato do SKU, comprimentos, `price > 0` e `updated_at >= created_at`. Timestamps são `timestamptz` (UTC, microssegundos).
