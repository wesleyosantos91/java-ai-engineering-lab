---
name: performance-optimization
description: >-
  Conduz investigação e otimização de desempenho deste repositório com medição
  antes e depois, protocolo reproduzível e análise de trade-offs de latência,
  throughput, CPU e memória. Use quando houver problema de desempenho, mudança com
  impacto relevante ou novo cenário de carga. Não use para otimizar sem medição
  nem para declarar metas absolutas não definidas no PRD.
---

# Performance Optimization

## Princípios do projeto

O [ADR-0001](../../../docs/architecture/adr/0001-architecture-principles.md) exige medir antes de otimizar e registrar ambiente e metodologia. O [PRD](../../../docs/product/prd.md) só admite metas absolutas definidas por protocolo reproduzível. A [DoD, seção 6](../../../docs/engineering/definition-of-done.md) define as evidências.

## Estado atual das ferramentas

- **Operacional:** smoke de disponibilidade `performance/k6/smoke.js`, executado por `bash scripts/performance/smoke.sh` contra uma aplicação já em execução (`BASE_URL`, padrão `http://localhost:8080`; suba com `bash ./mvnw spring-boot:test-run`). Ele verifica só status 200 e health `UP`, sem metas de latência; os números que o k6 imprime **não** são medição de desempenho aprovada. Detalhes no [guia de testes](../../../docs/how-to/run-tests.md#performance).
- **Ainda não existem:** cenários de load e stress e Docker Compose. Crie-os somente quando `/api/v1/products` existir e houver um protocolo de medição escrito (seção abaixo):
  - `performance/k6/<cenário>.js`, parametrizado por `BASE_URL`, com thresholds derivados do protocolo, nunca inventados;
  - um script em `scripts/performance/`, com o contrato de saída do harness (`0` PASS, `3` SKIP, `1` FAIL) e relatório bruto em `target/performance/`;
  - `compose.yaml` na raiz somente quando o sidecar do Datadog Agent previsto no ADR-0001 for implementado. Para PostgreSQL local, use a `TestJavaAiEngineeringLabApplication` (Testcontainers).
- JFR, Virtual Threads, Spring AOT e JVM AOT Cache são objetos de investigação previstos no ADR, não configurações ativas.

## Procedimento

1. **Defina a pergunta** — Indicador (p95, p99, throughput, CPU, memória, alocação), cenário e critério de sucesso.
2. **Registre o ambiente** — Hardware, sistema operacional, versão do Java, flags da JVM, versão da aplicação, banco e dados de carga.
3. **Baseline** — Meça antes de alterar, com aquecimento e várias repetições. Registre dispersão, não apenas a média.
4. **Diagnostique** — Use profiling (por exemplo JFR) e `EXPLAIN ANALYZE` no PostgreSQL para localizar o gargalo real.
5. **Altere uma variável por vez** — Uma otimização por medição.
6. **Meça novamente** — Mesmas condições do baseline.
7. **Analise trade-offs** — Ganho versus complexidade, memória, legibilidade e riscos de concorrência.
8. **Preserve a correção** — Execute `bash scripts/verify.sh` após a mudança.

## Regras de relato

- Diferencie medição observada de estimativa.
- Não invente números nem extrapole de execuções únicas.
- Inclua comandos, scripts de carga e dados brutos ou sua localização.
- Registre o protocolo de medição (pergunta, ambiente, baseline, repetições e critério) junto da feature, em `design.md`, antes de executar.
