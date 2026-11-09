# PRD-001 — Product Catalog API

**Projeto:** Java AI Engineering Lab  
**Versão do documento:** 0.1  
**Status:** Proposto — aguardando validação  
**Responsável pela aprovação:** Responsável técnico do projeto

## 1. Contexto

O Java AI Engineering Lab é um laboratório para estudar engenharia de software com Java 27, Spring Boot 4 e agentes de inteligência artificial.

A Product Catalog API será utilizada como caso de estudo para implementar, testar e comparar abordagens AI-Assisted e AI-First.

O foco é construir uma funcionalidade suficientemente simples para permitir experimentos reproduzíveis, mas com regras que permitam avaliar qualidade de código, integridade de dados, arquitetura e tratamento de falhas.

## 2. Objetivos

- Disponibilizar uma API REST de gerenciamento de produtos.
- Aplicar regras de domínio independentes da infraestrutura.
- Garantir integridade e unicidade dos registros.
- Definir contratos de entrada e saída consistentes.
- Permitir avaliação funcional independente da implementação.
- Utilizar os mesmos requisitos nos experimentos comparativos.

## 3. Escopo funcional

O sistema deverá permitir:

- Criar um produto.
- Consultar um produto pelo identificador.
- Listar produtos com paginação.
- Atualizar integralmente um produto.
- Excluir um produto.
- Rejeitar operações que violem as regras de negócio.

## 4. Modelo de produto

| Campo | Tipo lógico | Regra |
|---|---|---|
| `id` | UUID | Obrigatório, gerado pelo servidor e imutável |
| `sku` | String | Obrigatório, único e normalizado |
| `name` | String | Obrigatório, entre 3 e 120 caracteres |
| `description` | String ou null | Opcional, máximo de 500 caracteres |
| `price` | Decimal | Obrigatório, maior que zero e com até 2 casas decimais |
| `createdAt` | Timestamp | Gerado na criação, imutável |
| `updatedAt` | Timestamp | Gerado na criação e atualizado nas alterações |

### 4.1 Regras do SKU

- Remover espaços no início e no final.
- Converter letras para maiúsculas.
- Permitir de 3 a 32 caracteres.
- Aceitar letras de A a Z, números de 0 a 9, hífen e underscore.
- O primeiro caractere deverá ser uma letra ou um número.
- Garantir unicidade após normalização.
- Tratar `abc-001` e `ABC-001` como o mesmo SKU.

### 4.2 Regras do nome e da descrição

- O nome deve ser validado após remoção de espaços externos.
- Nomes vazios ou com apenas espaços são inválidos.
- A descrição poderá ser omitida ou informada como `null`.
- Uma descrição informada e não nula não poderá conter apenas espaços.

### 4.3 Regras do preço

- O preço representa um valor em reais (BRL).
- Deve ser representado internamente com precisão decimal.
- Não aceitar valores negativos ou iguais a zero.
- Não aceitar valores com mais de duas casas decimais.
- Não realizar arredondamento silencioso.
- O limite superior será R$ 99.999.999,99.

### 4.4 Datas

- Utilizar timestamps em UTC.
- Representar datas na API em formato ISO 8601.
- `createdAt` não poderá mudar após a criação.
- `updatedAt` deverá refletir alterações bem-sucedidas.

## 5. Contrato HTTP

URL base: `/api/v1/products`

| Operação | Método e caminho | Sucesso |
|---|---|---|
| Criar | `POST /api/v1/products` | `201 Created` |
| Consultar | `GET /api/v1/products/{id}` | `200 OK` |
| Listar | `GET /api/v1/products` | `200 OK` |
| Atualizar | `PUT /api/v1/products/{id}` | `200 OK` |
| Excluir | `DELETE /api/v1/products/{id}` | `204 No Content` |

### 5.1 Criação

A requisição deverá conter `sku`, `name` e `price`.

O campo `description` será opcional.

O servidor deverá gerar `id`, `createdAt` e `updatedAt`.

A resposta de sucesso deverá conter a representação completa do produto.

O cabeçalho `Location` deverá identificar o recurso criado.

Uma tentativa de criar um SKU já existente deverá retornar `409 Conflict`.

### 5.2 Consulta

Uma consulta por identificador existente deverá retornar a representação completa do produto.

Um UUID válido que não corresponda a um produto deverá resultar em `404 Not Found`.

Um identificador com formato UUID inválido deverá resultar em `400 Bad Request`.

### 5.3 Listagem e paginação

Parâmetros aceitos:

- `page`: índice da página, iniciando em zero. Padrão: `0`.
- `size`: quantidade de registros por página. Padrão: `20`. Valores aceitos: de `1` a `100`.

A ordenação padrão deverá ser por `createdAt` decrescente, utilizando `id` crescente como critério de desempate.

A resposta deverá apresentar:

- `content`: produtos da página.
- `page`: índice solicitado.
- `size`: tamanho solicitado.
- `totalElements`: total de produtos.
- `totalPages`: total de páginas.

Parâmetros de paginação inválidos deverão retornar `400 Bad Request`.

Uma listagem sem produtos deverá retornar `200 OK` com `content` vazio e totais iguais a zero.

### 5.4 Atualização

A operação utilizará `PUT`, com substituição integral dos campos editáveis.

Campos obrigatórios: `sku`, `name` e `price`.

A ausência de `description` será interpretada como ausência de descrição.

Não será permitido alterar `id` ou `createdAt`.

O retorno deverá conter a representação completa e atualizada.

Um produto inexistente deverá retornar `404 Not Found`.

Uma tentativa de utilizar SKU pertencente a outro produto deverá retornar `409 Conflict`.

### 5.5 Exclusão

A exclusão será física nesta versão.

Uma exclusão bem-sucedida deverá retornar `204 No Content`, sem corpo.

Tentar excluir um produto inexistente deverá retornar `404 Not Found`, inclusive quando o mesmo identificador já tiver sido excluído anteriormente.

## 6. Contrato de representação

### 6.1 Requisições de criação e atualização

Campos aceitos no corpo JSON:

- `sku`: string.
- `name`: string.
- `description`: string ou null, opcional.
- `price`: número JSON decimal.

Campos gerenciados pelo servidor não deverão ser aceitos como campos editáveis.

### 6.2 Resposta de produto

A representação deverá conter:

- `id`
- `sku`
- `name`
- `description`
- `price`
- `createdAt`
- `updatedAt`

### 6.3 Erros

As respostas de erro deverão utilizar o formato `ProblemDetail`, compatível com RFC 9457, com conteúdo `application/problem+json`.

Os campos padrão serão `type`, `title`, `status`, `detail` e `instance`, conforme aplicável.

A API também deverá fornecer uma propriedade de extensão `code` para identificar o tipo de erro de forma estável.

Códigos definidos inicialmente:

- `VALIDATION_FAILED`
- `PRODUCT_NOT_FOUND`
- `PRODUCT_SKU_CONFLICT`

Detalhes técnicos internos, comandos SQL, credenciais e stack traces não deverão ser expostos ao cliente.

## 7. Integridade e concorrência

A unicidade do SKU deverá ser garantida também pelo banco de dados, e não somente por uma consulta prévia.

Em duas tentativas concorrentes de criação com o mesmo SKU, apenas uma poderá ser persistida.

O resultado esperado é:

- Uma requisição