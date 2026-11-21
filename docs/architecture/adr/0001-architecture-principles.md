
# ADR-0001: Princípios de arquitetura

## Status

Aceita

## Contexto

Este repositório é um laboratório de engenharia de software para estudar e avaliar o desenvolvimento AI-First com Java 27 e Spring Boot 4.

O projeto deve permitir a comparação controlada entre desenvolvimento AI-Assisted e AI-First, mantendo qualidade, rastreabilidade, segurança e reprodutibilidade.

## Decisão

### Linguagem e framework

- Utilizar Java 27 e Spring Boot 4.
- Priorizar recursos nativos da plataforma Java.
- Introduzir bibliotecas somente quando houver justificativa técnica.

### Arquitetura

- Organizar o código de negócio por funcionalidade (Feature-Based).
- Manter regras de negócio independentes de HTTP e persistência.
- Evitar abstrações especulativas e complexidade acidental.
- Aplicar SOLID, KISS e YAGNI conforme o contexto.
- Registrar decisões relevantes em ADRs.

### Persistência

- Utilizar PostgreSQL e Spring JDBC, com SQL explícito.
- Versionar alterações de esquema com Flyway.
- Utilizar Testcontainers nos testes de integração.
- Avaliar transações, isolamento e índices com evidências.

### Qualidade

- Desenvolver testes automatizados para comportamentos relevantes.
- Aplicar TDD quando adequado e BDD para cenários de negócio.
- Configurar futuramente JaCoCo, PIT e testes arquiteturais.
- Não confundir cobertura de código com qualidade dos testes.

### Observabilidade

- Utilizar Datadog Java Tracer para instrumentação APM.
- Utilizar Datadog Agent em container sidecar.
- Encaminhar métricas customizadas por DogStatsD.
- Adotar logs estruturados e correlação com traces.
- Investigar tráfego, erros, latência e saturação.

### Performance

- Medir antes de otimizar.
- Avaliar throughput, p95, p99, consumo de CPU e memória.
- Investigar Virtual Threads, JFR, Spring AOT e JVM AOT Cache.
- Registrar ambiente e metodologia dos experimentos.

### AI-First

- Manter instruções versionadas para agentes.
- Definir limites de autonomia e critérios de aceitação.
- Exigir revisão humana para decisões arquiteturais relevantes.
- Não aceitar resultados declarados sem evidências verificáveis.
- Comparar abordagens com critérios equivalentes.

## Alternativas consideradas

- Spring Data JPA: não adotado inicialmente para favorecer o estudo de SQL e JDBC.
- Arquitetura por camadas técnicas: não adotada como organização principal; a preferência é Feature-Based.
- Exportação direta de métricas ao Datadog: não adotada inicialmente; será utilizado o Agent sidecar.

## Consequências positivas

- Maior visibilidade dos mecanismos de persistência.
- Fronteiras de funcionalidades mais explícitas.
- Melhor capacidade de investigação de performance.
- Experimentos de engenharia mais reproduzíveis.

## Consequências negativas

- Maior responsabilidade por SQL e mapeamentos.
- Necessidade de disciplinar fronteiras arquiteturais.
- Mais configuração manual e manutenção.

## Validação

As decisões serão verificadas por revisão de código, testes automatizados, testes arquiteturais, benchmarks e análise de trade-offs.

## Revisão da decisão

Este ADR deverá ser revisado quando novas evidências justificarem alterações. Mudanças relevantes deverão ser documentadas em novos ADRs, preservando o histórico.
  