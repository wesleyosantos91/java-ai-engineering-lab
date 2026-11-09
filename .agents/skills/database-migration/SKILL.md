---
name: database-migration
description: >-
  Cria e revisa migrações Flyway e SQL explícito com Spring JDBC para PostgreSQL no Java
  AI Engineering Lab, cobrindo versionamento, restrições, índices, transações e testes
  com Testcontainers. Use ao alterar esquema, escrever repository ou consulta SQL. Não
  use para introduzir JPA ou alterar migrações já aplicadas.
---

# Database Migration

## Contexto atual

- Migrações em `src/main/resources/db/migration/`, executadas pelo Flyway na inicialização.
- PostgreSQL nos testes via Testcontainers (`TestcontainersConfiguration`).
- Persistência com Spring JDBC e SQL explícito; JPA não é adotado.
- Requisitos de integridade no [PRD, seção 7](../../../docs/product/prd.md) e obrigações na [DoD, seção 4](../../../docs/engineering/definition-of-done.md).

## Migrações

1. Nomeie como `V<versão>__<descricao_em_snake_case>.sql`, com versão sequencial e sem lacunas ambíguas.
2. Nunca edite uma migração já aplicada em algum ambiente ou já integrada; crie uma nova.
3. Garanta integridade no banco, não apenas na aplicação: `NOT NULL`, `CHECK`, `UNIQUE` e chaves estrangeiras quando exigidas pelo contrato. Exemplo: unicidade do SKU normalizado por restrição `UNIQUE`.
4. Considere dados existentes: colunas `NOT NULL` novas precisam de default ou migração de dados.
5. Crie índices para consultas e ordenações previstas, como paginação, justificando cada um.
6. Mantenha uma mudança coesa por migração.

## SQL e repositories

- Use parâmetros nomeados ou posicionais; nunca concatene entrada do usuário em SQL.
- Selecione colunas explícitas, sem `SELECT *`.
- Mapeie resultados em mapper dedicado da `persistence`.
- Traduza violações de restrição (por exemplo `DuplicateKeyException`) para exceções de domínio no ponto adequado, sem expor SQL na resposta.
- Defina transações no `service` com `@Transactional` quando houver múltiplas operações ou leitura seguida de escrita.

## Testes

- Teste migração e repository em `*IT` com PostgreSQL real via Testcontainers, não com banco em memória.
- Cubra restrições de banco, inclusive concorrência quando o contrato exigir, como o CA-08 de SKU duplicado.
- Execute `bash scripts/test-integration.sh` ou `bash scripts/verify.sh`; Docker é obrigatório.

## Proibições

Credenciais em código ou migrações, `DROP` ou `TRUNCATE` sem autorização explícita, e alterar migração aplicada para corrigir erro.
