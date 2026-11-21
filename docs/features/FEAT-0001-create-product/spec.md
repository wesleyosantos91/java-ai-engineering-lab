# Especificação de feature — Criar produto

## 1. Identificação

| Campo | Valor |
|---|---|
| ID | FEAT-0001 |
| Nome | Criar produto (`POST /api/v1/products`) |
| Status | Em validação |
| Responsável | Wesley Oliveira Santos |
| Contrato de referência | [PRD-001](../../product/prd.md) versão 1.0 (aprovada): §4 (modelo e regras), §5.1 (criação), §6 (representação e erros), §7 (integridade e concorrência), §8 (CA-01, CA-02, CA-03, CA-08, CA-10, CA-11). A versão 1.1, em revisão, não altera essas seções. ADRs: [0001](../../architecture/adr/0001-architecture-principles.md); [0003](../../architecture/adr/0003-test-suites-and-quality-gates.md) (proposto) |
| Branch | `feature/feat-0001-create-product` |
| Issue ou PR relacionado | Ainda não criado |
| Dependências | Nenhuma identificada. É a primeira feature e cria o esquema inicial (`V1`) |
| Referência da aprovação | Aprovação de Wesley Oliveira Santos na sessão de 2026-11-20 (seção 13) |

O escopo foi aprovado em 2026-11-20 (seção 13); mudanças de escopo exigem nova aprovação. Consulte o [AGENTS.md](../../../AGENTS.md) e o [catálogo](../README.md).

## 2. Contexto e problema

O PRD-001 define a Product Catalog API, mas nenhuma operação foi implementada. A criação de produto é a primeira operação necessária: sem ela não há dados para consulta, listagem, atualização ou exclusão.

Ela também é a primeira demonstração ponta a ponta do método do repositório (spec → plano → TDD → harness → revisão). Hoje os quality gates JaCoCo, PIT e a maior parte das regras ArchUnit retornam SKIP por falta de código elegível.

## 3. Objetivo

Permitir criar um produto válido via `POST /api/v1/products`, garantindo normalização, validação, unicidade do SKU (inclusive sob concorrência) e erros no formato `ProblemDetail`.

Verificação: os cenários da seção 6 passam em testes automatizados, e `bash scripts/verify.sh` e `bash scripts/quality/mutation.sh` terminam em PASS nas metas vigentes (LINE e BRANCH ≥ 90%, mutation score ≥ 90%, ArchUnit sem violações).

## 4. Escopo

### Incluído

- Endpoint `POST /api/v1/products` com corpo JSON `sku`, `name`, `description` (opcional) e `price`.
- Normalização e validação de SKU, nome, descrição e preço conforme PRD §4.1 a §4.3.
- Geração de `id` (UUID), `createdAt` e `updatedAt` (UTC) pelo servidor; na criação, `updatedAt` = `createdAt`.
- Resposta `201 Created` com a representação completa (PRD §6.2) e o cabeçalho `Location`.
- Erros `400` (`VALIDATION_FAILED`) e `409` (`PRODUCT_SKU_CONFLICT`) em `application/problem+json` (PRD §6.3).
- Unicidade do SKU normalizado garantida por restrição `UNIQUE` no PostgreSQL e traduzida para `409` (PRD §7).
- Migração Flyway `V1` criando a tabela de produtos.

### Fora do escopo

- Consulta, listagem, atualização e exclusão (PRD §5.2 a §5.5), previstas para FEAT-0002 em diante. Até lá, o `Location` retornado aponta para um recurso que ainda não pode ser consultado via `GET`.
- CA-04, CA-05, CA-06, CA-07 e CA-09, e as partes de atualização de CA-10 e CA-11.
- Autenticação, observabilidade customizada e metas de desempenho (PRD §9 e §10).

### Histórico de escopo e estados

| Data | Estado ou escopo anterior → novo | Motivo e impactos | Responsável | Decisão e referência verificável |
|---|---|---|---|---|
| 2026-11-20 | — → Proposta | Registro inicial da primeira feature do PRD-001, como exemplo ponta a ponta do repositório de referência | Agente (Claude Code), a pedido de Wesley Oliveira Santos | Solicitação na sessão de 2026-11-20 |
| 2026-11-20 | Proposta → Aprovada | Escopo e decisões D-01 a D-06 aprovados sem ajustes | Wesley Oliveira Santos | Resposta explícita "Aprovar tudo" na sessão de 2026-11-20 |
| 2026-11-20 | Aprovada → Em implementação | Início da implementação com TDD na branch `feature/feat-0001-create-product` | Agente (Claude Code) | Aprovação acima |
| 2026-11-20 | Em implementação → Em validação | Implementação concluída; evidências na seção 12; aguardando revisão humana | Agente (Claude Code) | Seção 12 |

### Impedimentos

Nenhum identificado.

## 5. Requisitos funcionais

| Referência | Comportamento observável e regras | Entradas e saídas | Falhas esperadas | Fonte contratual |
|---|---|---|---|---|
| RF-01 | Criar produto válido, persistindo os valores normalizados | `POST` com `sku`, `name`, `price` e `description` opcional → `201`, corpo completo e `Location: /api/v1/products/{id}` | — | PRD 1.0 §5.1, §6.2; CA-01 |
| RF-02 | Normalizar SKU: remover espaços externos, converter para maiúsculas; 3 a 32 caracteres `[A-Z0-9_-]`, iniciando por letra ou número | `" abc-001 "` → `ABC-001` | Fora da regra → `400 VALIDATION_FAILED` | PRD 1.0 §4.1 |
| RF-03 | Validar nome após remover espaços externos: 3 a 120 caracteres; vazio ou só espaços é inválido | `"  Caneta  "` → `Caneta` | Fora da regra → `400` | PRD 1.0 §4.2 |
| RF-04 | Normalizar descrição: omitida, `null`, `""` ou só espaços → `null`; caso contrário, remover espaços externos e exigir no máximo 500 caracteres | `"   "` → `null` | Mais de 500 após normalização → `400` | PRD 1.0 §4.2; CA-11 |
| RF-05 | Validar preço: número JSON decimal, maior que zero, no máximo 2 casas decimais e no máximo 99.999.999,99, sem arredondamento | `10.50` aceito | `0`, negativo, `10.505`, acima do limite → `400` | PRD 1.0 §4.3; CA-03 |
| RF-06 | Rejeitar SKU já existente após normalização, com unicidade garantida pelo banco, inclusive sob concorrência | Segundo `POST` com `abc-001` após `ABC-001` → `409` | `409 PRODUCT_SKU_CONFLICT`; nada é persistido | PRD 1.0 §5.1, §7; CA-02, CA-08 |
| RF-07 | Rejeitar propriedades JSON desconhecidas ou gerenciadas pelo servidor (`id`, `createdAt`, `updatedAt`, outras) | `{"id": "...", ...}` → `400` | `400 VALIDATION_FAILED`; nada é persistido | PRD 1.0 §6.1.1; CA-10 |
| RF-08 | Responder erros em `application/problem+json`, com `type`, `title`, `status`, `detail`, `instance` e a extensão `code`, sem SQL, stack trace ou detalhes internos | — | — | PRD 1.0 §6.3 |
| RF-09 | Rejeitar corpo ausente, JSON malformado e campos obrigatórios ausentes ou `null` | — | `400 VALIDATION_FAILED` | PRD 1.0 §5.1, §6.1 |

### 5.1 Decisões complementares ao PRD

O PRD não fixa estes pontos. As decisões abaixo foram aprovadas em 2026-11-20 (seção 13).

| ID | Questão | Decisão |
|---|---|---|
| D-01 | Preço enviado como string JSON (`"10.50"`) | **Rejeitar** com `400`: o PRD exige "número JSON decimal" (§6.1) |
| D-02 | Preço com zeros à direita além de 2 casas (`10.500`) | **Aceitar** como `10.50`: o valor tem no máximo 2 casas significativas, sem arredondamento. `10.505` é rejeitado |
| D-03 | Detalhe dos erros de validação | Extensão `errors`: lista de `{ "field": "...", "message": "..." }` com todas as violações, além de `code` |
| D-04 | Formato do `Location` | URI absoluta construída a partir da requisição, por exemplo `http://host/api/v1/products/{id}` |
| D-05 | Representação de `price` na resposta | Número JSON com 2 casas (`10.50`) |
| D-06 | Precisão de `createdAt` e `updatedAt` | ISO 8601 em UTC com sufixo `Z`, truncado a microssegundos (precisão do `timestamptz` do PostgreSQL), para que a resposta seja igual ao valor persistido |

## 6. Critérios de aceitação BDD

### Cenário CA-01 — Criação válida

**Requisito relacionado:** RF-01, RF-02, RF-03, RF-05; PRD CA-01

**Dado** que não existe produto com SKU `ABC-001`

**Quando** for enviado `POST /api/v1/products` com `{"sku": " abc-001 ", "name": " Caneta azul ", "description": "Tinta gel", "price": 12.90}`

**Então** a API retorna `201 Created` com `sku` `ABC-001`, `name` `Caneta azul`, `description` `Tinta gel` e `price` `12.90`, além de `id`, `createdAt` e `updatedAt` gerados, com `updatedAt` igual a `createdAt`
**E** o cabeçalho `Location` termina em `/api/v1/products/{id}` do produto criado
**E** o produto está persistido com os valores normalizados.

**Como comprovar:** `ProductCreationIT` (HTTP + PostgreSQL via Testcontainers).

### Cenário CA-02 — SKU duplicado após normalização

**Requisito relacionado:** RF-06; PRD CA-02

**Dado** um produto com SKU `ABC-001`

**Quando** for solicitada a criação com SKU `abc-001`

**Então** a API retorna `409 Conflict` com `code` `PRODUCT_SKU_CONFLICT`
**E** continua existindo um único produto com esse SKU.

**Como comprovar:** `ProductCreationIT`.

### Cenário CA-03 — Preço inválido

**Requisito relacionado:** RF-05; PRD CA-03

**Dado** um preço igual a `0` (e, como limites, `-1`, `10.505` e `100000000.00`)

**Quando** a criação for solicitada

**Então** a API retorna `400 Bad Request` com `code` `VALIDATION_FAILED` e o campo `price` em `errors`
**E** nenhum produto é persistido.

**Como comprovar:** `ProductCreationIT` (HTTP) e testes unitários de `Price` (limites `0.01`, `99999999.99`, escala).

### Cenário CA-08 — Concorrência

**Requisito relacionado:** RF-06; PRD CA-08

**Dadas** duas requisições simultâneas de criação com o mesmo SKU normalizado

**Quando** ambas forem processadas

**Então** exatamente uma retorna `201` e a outra `409 PRODUCT_SKU_CONFLICT`
**E** existe um único registro no banco.

**Como comprovar:** `ProductConcurrencyIT`, com as requisições liberadas ao mesmo tempo por uma barreira e repetido várias vezes para reduzir falsos positivos.

### Cenário CA-10 — Campo JSON desconhecido

**Requisito relacionado:** RF-07; PRD CA-10

**Dada** uma requisição de criação contendo `id`, `createdAt`, `updatedAt` ou um campo não previsto (por exemplo `stock`)

**Quando** a requisição for processada

**Então** a API retorna `400 Bad Request` com `code` `VALIDATION_FAILED`
**E** nenhum produto é persistido.

**Como comprovar:** `ProductCreationIT`, com um caso para cada campo.

### Cenário CA-11 — Normalização da descrição

**Requisito relacionado:** RF-04; PRD CA-11

**Dada** uma requisição válida com `description` omitida, `null`, `""` ou `"   "`

**Quando** o produto for criado

**Então** a operação é aceita com `201`
**E** a descrição retornada e armazenada é `null`.

**Como comprovar:** `ProductCreationIT` e testes unitários de `ProductDescription` (incluindo exatamente 500 e 501 caracteres após normalização).

### Cenário VAL-01 — Regras de SKU e nome

**Requisito relacionado:** RF-02, RF-03, RF-09

**Dado** um SKU com 2 ou 33 caracteres, um caractere fora de `[A-Z0-9_-]`, iniciando por `-` ou `_`, ou um nome com menos de 3 ou mais de 120 caracteres após normalização, ou ainda um campo obrigatório ausente ou `null`

**Quando** a criação for solicitada

**Então** a API retorna `400 VALIDATION_FAILED`, com o campo correspondente em `errors`, e nada é persistido.

**Como comprovar:** testes unitários de `Sku` e `ProductName` (limites 3/32 e 3/120) e um caso HTTP representativo em `ProductCreationIT`.

### Cenário ERR-01 — Erros sem detalhes internos

**Requisito relacionado:** RF-08, RF-09

**Dado** um corpo ausente, um JSON malformado ou qualquer erro das seções anteriores

**Quando** a resposta de erro for emitida

**Então** o `Content-Type` é `application/problem+json`, com `status`, `title` e `code`
**E** o corpo não contém SQL, nomes de tabela ou constraint, classes Java nem stack trace.

**Como comprovar:** `ProductCreationIT`, com asserções negativas sobre o corpo.

## 7. Requisitos não funcionais

| Aspecto | Requisito aplicável e fonte | Método de verificação ou justificativa |
|---|---|---|
| Segurança | Não expor SQL, credenciais ou stack traces (PRD §9 Segurança); SQL somente parametrizado | ERR-01; revisão pela skill `security-review`; `bash scripts/security/scan-secrets.sh` |
| Performance | Não aplicável: o PRD não define metas sem protocolo de medição | Smoke de disponibilidade existente não muda |
| Observabilidade | Não aplicável nesta feature (instrumentação futura, PRD §9) | — |
| Disponibilidade e confiabilidade | Não aplicável | — |
| Concorrência | Uma única criação por SKU sob requisições simultâneas (PRD §7) | CA-08 em `ProductConcurrencyIT` |
| Integridade de dados | Restrições no banco espelham as regras: `UNIQUE` no SKU, `CHECK` de preço, comprimentos e `NOT NULL` | Migração `V1` aplicada pelo Flyway nos testes de integração; CA-02 e CA-08 |

## 8. Considerações técnicas

| Aspecto | Avaliação |
|---|---|
| Impacto arquitetural | Primeira feature em `io.github.wesleyosantos91.catalog.feature.product`, conforme as [convenções de packages](../../architecture/package-conventions.md) e as [regras de dependência](../../architecture/dependency-rules.md). As regras ArchUnit passam a ter classes elegíveis |
| Packages e features envolvidos | Criados somente os necessários: `feature/product/{api/rest/v1/{request,response},service,domain/{entity,valueobject,exception},persistence/repository}` e `shared/configuration` (bean `Clock`). Sem `mapper/`: a conversão cabe em métodos dos próprios records. O tratamento de erros fica em `api/rest/v1/ProductExceptionHandler`, limitado ao controller, para que `shared` não dependa da feature. **Fronteira:** `api` depende só de `service` (`CreateProductCommand`, `ProductDetails`, exceções do service), nunca de `domain`, conforme a lista de dependências permitidas; o service traduz as exceções do domínio |
| Persistência e transações | Migração `V1__create_product.sql`: tabela `product` com `id uuid` PK, `sku varchar(32) UNIQUE` com `CHECK` de formato, `name varchar(120)`, `description varchar(500)` nulo, `price numeric(10,2)` com `CHECK (price > 0)`, `created_at` e `updated_at` `timestamptz`. Spring JDBC (`JdbcClient`) com SQL explícito. Inserção em transação de serviço; o conflito de unicidade vem do banco e não de consulta prévia (PRD §7) |
| Integrações | Não aplicável |
| Dependências técnicas e entre features | Nenhuma nova dependência Maven prevista; usa os starters já declarados (`webmvc`, `jdbc`, `flyway`, `validation`) |
| Riscos e trade-offs | (1) Jackson 3.1.7 ignora propriedades desconhecidas por padrão; a rejeição usa `spring.jackson.deserialization.fail-on-unknown-properties: true` (global, coerente com o PRD §6.1.1, que vale para criação e atualização). A coerção de string para número é bloqueada por `JsonNumberOnlyDeserializer` só no `price`. Ambos comprovados em `ProductCreationIT`. (2) O teste de concorrência é probabilístico: barreira e 10 repetições. (3) Timestamps truncados a microssegundos (D-06), comprovado comparando resposta e banco. (4) Erros de leitura do JSON (campo desconhecido, tipo) são detectados antes das regras de negócio e reportam apenas o primeiro campo. (5) O nome de uma propriedade desconhecida é ecoado em `errors`, codificado em JSON: risco baixo, registrado na revisão de segurança |
| Necessidade de ADR | Não: a feature aplica decisões existentes (ADR-0001) |
| Necessidade de design.md | Não: as considerações cabem nesta seção |

## 9. Estratégia de testes

| Tipo | Cenários e critérios cobertos | Comando ou método previsto | Aplicabilidade e limitações |
|---|---|---|---|
| Unitários | Limites de `Sku`, `ProductName`, `ProductDescription` e `Price` (VAL-01, CA-03, CA-11); criação da entidade com `Clock` fixo; serviço com repository simulado traduzindo conflito (CA-02) | `bash scripts/test/unit.sh` | Sem Spring nem Docker |
| Integração | CA-01, CA-02, CA-03, CA-10, CA-11, VAL-01, ERR-01 via HTTP e PostgreSQL; migração Flyway | `bash scripts/test/integration.sh` | Exige Docker |
| Contrato | Status, cabeçalhos, `application/problem+json`, campos de resposta | Incluídos em `ProductCreationIT` | Testes externos de contrato (PRD §9 Qualidade) ficam fora do escopo |
| Falhas e situações-limite | Limites de comprimento, escala e valor; corpo ausente; JSON malformado | Unitários e `ProductCreationIT` | — |
| Concorrência | CA-08 | `ProductConcurrencyIT` | Probabilístico; repetições na mesma execução |
| Quality gates configurados | ArchUnit, JaCoCo (LINE/BRANCH ≥ 90%) e PIT (≥ 90% em `domain` e `service`) | `bash scripts/verify.sh` e `bash scripts/quality/mutation.sh` | Metas não podem ser reduzidas |

Cada comportamento segue o ciclo Red, Green e Refactor da skill `tdd-workflow`, com evidência registrada na seção 12.

## 10. Documentação impactada

| Documento existente ou destino futuro explícito | Categoria ou finalidade | Alteração necessária | Situação e evidência |
|---|---|---|---|
| [Catálogo de features](../README.md) | Governança | Linha FEAT-0001 com status sincronizado | Registrada como Proposta |
| [README](../../../README.md) | Navegação | Tabela "Estado atual": endpoint de criação e quality gates | Atualizado |
| [Guia de testes](../../how-to/run-tests.md) | How-to | Testes de negócio existentes e estado dos gates | Atualizado |
| [Referência da API](../../reference/api/products.md) | Referência | Contrato de `POST /api/v1/products` com exemplos reais | Criada com saídas reais de 2026-11-20 |

## 11. Critérios de conclusão

Conforme a [Definition of Done](../../engineering/definition-of-done.md):

- [ ] Escopo e critérios de aceitação aprovados foram atendidos, incluindo sucesso, falhas e limites.
- [ ] Comportamento implementado corresponde ao contrato e não inclui funcionalidades fora do escopo.
- [ ] Arquitetura, fronteiras, dependências e organização Feature-Based foram respeitadas.
- [ ] Testes pertinentes foram implementados e executados, com resultados, falhas e omissões registrados.
- [ ] Quality gates (ArchUnit, JaCoCo, PIT) foram executados e aprovados nas metas vigentes.
- [ ] Persistência, migração e transações foram verificadas.
- [ ] Segurança avaliada (skill `security-review`) e varredura de segredos executada.
- [ ] Documentação técnica, especificação e catálogo foram atualizados e seus links revisados.
- [ ] Participação dos agentes, decisões e evidências estão rastreáveis, sem resultados inventados.
- [ ] Referências de entrega registradas; commits e PRs somente com autorização.
- [ ] Pendências e exceções tratadas conforme a DoD.
- [ ] Revisão humana favorável registrada antes da transição para Concluída.

## 12. Evidências

### Execuções e resultados

| Data e ambiente | Critério BDD ou item da DoD | Comando realmente executado ou método utilizado | Resultado observado e referência da evidência |
|---|---|---|---|
| 2026-11-20, Windows 11, Java 27, Docker Desktop, PostgreSQL 18.2 (Testcontainers) | TDD ciclo 1 (value objects): Red | `bash scripts/test/unit.sh` com `SkuTest`, `ProductNameTest`, `ProductDescriptionTest` e `PriceTest` antes da implementação | FAIL: `COMPILATION ERROR`, `cannot find symbol` (tipos inexistentes) |
| idem | TDD ciclo 1: Green | `bash scripts/test/unit.sh` | PASS: 49 testes |
| idem | TDD ciclo 2 (entidade e service): Red → Green | `bash scripts/test/unit.sh` com `ProductTest` e `ProductServiceTest` | Red: `cannot find symbol` (`Product`, `ProductService`, ...). Green: PASS, 57 testes |
| idem | TDD ciclo 3 (HTTP + banco): Red | `bash scripts/test/integration.sh` com `ProductCreationIT` e `ProductConcurrencyIT` | FAIL: 33 erros; contexto não sobe (`No qualifying bean of type 'java.time.Clock'`; endpoint e tabela inexistentes) |
| idem | TDD ciclo 3: Green | `bash scripts/test/integration.sh` | PASS: 33 testes (incluindo 10 repetições de CA-08) |
| idem | Refactor e fluxo padrão | `bash scripts/verify.sh` | Agentes PASS; Build PASS; Unitários PASS (57); Arquitetura SKIP (7 regras PASS; 3 sem classes elegíveis: ciclos entre features, persistence de outra feature, producers); Integração PASS (33); Cobertura PASS (LINE 99,32%, 147/148; BRANCH 95,65%, 44/46); resultado PARCIAL por causa do SKIP legítimo da arquitetura |
| idem | Quality gate PIT | `bash scripts/quality/mutation.sh` | PASS: 43 mutantes, 43 mortos (100%), 0 sem cobertura |
| idem | CA-01, CA-02, VAL-01, CA-10 manual | `bash ./mvnw spring-boot:test-run` e `curl -X POST` | 201 com `Location` absoluta e descrição `null`; 409 `PRODUCT_SKU_CONFLICT`; 400 `VALIDATION_FAILED` com `errors` (saídas na [referência da API](../../reference/api/products.md)) |
| idem | Disponibilidade | `DURATION=5s bash scripts/performance/smoke.sh` | PASS: 3.154 requisições, 0% de falhas |
| idem | Segurança | `bash scripts/security/scan-secrets.sh`; busca por SQL concatenado e logs de exceção | PASS; nenhuma ocorrência |

### Verificações não executadas

| Teste ou verificação | Justificativa da omissão | Impacto na aceitação | Decisão ou ação pendente |
|---|---|---|---|
| ArchUnit: 3 regras | Exigem ao menos duas features ou código de mensageria, inexistentes | Não aplicável nesta feature; o resultado do `verify.sh` permanece PARCIAL | Passam a executar com a FEAT-0002+ ou com mensageria |
| Testes externos de contrato | Fora do escopo (seção 9) | Não bloqueia a aceitação da FEAT-0001 | A definir em feature própria |

### Referências de entrega

- Commits: ainda não criados.
- Pull requests: ainda não criados.
- Pendências e riscos: riscos da seção 8; a regra ArchUnit para a direção `api → domain` continua sem decisão (o código desta feature já respeita a direção restrita `api → service`).

### Participação de IA

| Campo | Registro |
|---|---|
| Agentes e modelos | Claude Code (Opus 5.5): especificação, TDD, implementação e verificação |
| Contratos de referência | PRD-001 1.0 (seções 4 a 8), ADR-0001, `docs/features/TEMPLATE.md` da branch `feature/ai-first-foundation` |
| Intervenções humanas | Escolha da FEAT-0001 como exemplo ponta a ponta e aprovação do escopo e de D-01 a D-06, ambas em 2026-11-20 |
| Aprendizados registrados | LL-0010, LL-0011 |

## 13. Aprovação

| Etapa | Decisão | Responsável humano | Data | Escopo ou revisão avaliada | Referência verificável |
|---|---|---|---|---|---|
| Aprovação do escopo | Aprovada sem ajustes | Wesley Oliveira Santos | 2026-11-20 | Esta especificação, incluindo D-01 a D-06 | Resposta "Aprovar tudo" na sessão do Claude Code de 2026-11-20 |
| Alteração do escopo, quando houver | Não aplicável | — | — | — | — |
| Revisão de conclusão | Pendente | — | — | — | — |
