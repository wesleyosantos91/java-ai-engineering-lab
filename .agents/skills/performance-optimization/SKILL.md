---
name: performance-optimization
description: >-
  Conduz investigação e otimização de desempenho do Java AI Engineering Lab com medição
  antes e depois, protocolo reproduzível e análise de trade-offs de latência,
  throughput, CPU e memória. Use quando houver problema de desempenho, mudança com
  impacto relevante ou experimento de performance. Não use para otimizar sem medição
  nem para declarar metas absolutas não definidas no PRD.
---

# Performance Optimization

## Princípios do projeto

O [ADR-0001](../../../docs/architecture/adr/0001-architecture-principles.md) exige medir antes de otimizar e registrar ambiente e metodologia. O [PRD](../../../docs/product/prd.md) só admite metas absolutas definidas por protocolo reproduzível. A [DoD, seção 6](../../../docs/engineering/definition-of-done.md) define as evidências.

## Estado atual das ferramentas

- `performance/k6/smoke.js`, `load.js` e `stress.js` existem, mas estão vazios.
- Não há script de performance no harness; não apresente medição automatizada como operacional.
- JFR, Virtual Threads, Spring AOT e JVM AOT Cache são objetos de investigação previstos no ADR, não configurações ativas.

## Procedimento

1. **Defina a pergunta** — Indicador (p95, p99, throughput, CPU, memória, alocação), cenário e critério de sucesso.
2. **Registre o ambiente** — Hardware, sistema operacional, versão do Java, flags da JVM, versão da aplicação, banco e dados de carga.
3. **Baseline** — Meça antes de alterar, com aquecimento e várias repetições. Registre dispersão, não apenas a média.
4. **Diagnostique** — Use profiling (por exemplo JFR) e `EXPLAIN ANALYZE` no PostgreSQL para localizar o gargalo real.
5. **Altere uma variável por vez** — Uma otimização por experimento.
6. **Meça novamente** — Mesmas condições do baseline.
7. **Analise trade-offs** — Ganho versus complexidade, memória, legibilidade e riscos de concorrência.
8. **Preserve a correção** — Execute `bash scripts/verify.sh` após a mudança.

## Regras de relato

- Diferencie medição observada de estimativa.
- Não invente números nem extrapole de execuções únicas.
- Inclua comandos, scripts de carga e dados brutos ou sua localização.
- Para experimentos comparativos, siga também a [skill experiment-protocol](../experiment-protocol/SKILL.md).
