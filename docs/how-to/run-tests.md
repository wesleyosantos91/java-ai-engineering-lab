# Executar e diagnosticar testes

Guia operacional para desenvolvedores e agentes. A Etapa 6A separa as suítes e fixa a infraestrutura de integração; a Etapa 6B configura os quality gates JaCoCo, ArchUnit e PIT. Nenhuma delas implementa requisitos de produto. PRD 1.0 e ADRs permanecem preservados.

## Pré-requisitos

- Windows 11 com Git Bash, ou ambiente Bash compatível.
- Java 27 no PATH; baseline validado com Temurin 27+35.
- Maven Wrapper versionado, que resolve Maven 3.10.0; não é necessário Maven global.
- Docker Desktop funcional com contêineres Linux para integração.
- Acesso aos repositórios Maven e Docker na primeira resolução dos artefatos.

Execute os comandos a partir da raiz. Os scripts também funcionam quando invocados pelo caminho absoluto de outro diretório, incluindo caminhos com espaços.

```bash
bash scripts/setup.sh
bash scripts/test-unit.sh
bash scripts/test-architecture.sh
bash scripts/test-integration.sh
bash scripts/test-coverage.sh     # após as suítes; não executa testes
bash scripts/verify.sh            # build, unitários, arquitetura, integração e cobertura
bash scripts/test-mutation.sh     # explícito; fora do verify.sh
```

## Escolher a suíte

| Suíte | Convenção exata em `src/test/java` | Plugin / fase | Relatórios XML e texto |
|---|---|---|---|
| Unitária | `*Test.java`, exceto `*ArchitectureTest.java` | Surefire 3.5.6 / `test` (execução `default-test`) | `target/surefire-reports/` |
| Arquitetura | `*ArchitectureTest.java` | Surefire 3.5.6 / `surefire:test@architecture`, sem fase | `target/architecture-reports/` |
| Integração | `*IT.java` | Failsafe 3.5.6 / `integration-test` e `verify` | `target/failsafe-reports/` |

As versões dos plugins são gerenciadas pelo parent Spring Boot 4.1.2. Não usar as convenções padrão alternativas `*Tests`, `Test*` ou `*ITCase` para novos testes: os includes do POM são explícitos. Classes auxiliares, como `TestcontainersConfiguration` e a aplicação de desenvolvimento `TestJavaAiEngineeringLabApplication`, não são testes executáveis.

Unitários não devem usar `@SpringBootTest`, importar a configuração de contêineres nem depender de Docker. O teste de contexto foi renomeado para `JavaAiEngineeringLabApplicationIT`; ele inicializa PostgreSQL com `@ServiceConnection` e verifica `SHOW server_version` por JDBC. Ainda não há testes unitários de produto nem integração de regras de negócio.

Comandos equivalentes ao Maven usado pelos scripts, quando houver classes elegíveis:

```bash
# Somente Surefire; não alcança as fases do Failsafe.
bash ./mvnw --batch-mode --no-transfer-progress test

# Somente Failsafe; mantém compilação dos testes e chega à verificação das falhas.
bash ./mvnw --batch-mode --no-transfer-progress -DskipUnitTests=true verify

# Ambas as suítes, quando ambas existirem.
bash ./mvnw --batch-mode --no-transfer-progress verify
```

`skipUnitTests` é uma propriedade local exclusiva do Surefire. Não usar `-DskipTests` para executar somente integração: no Failsafe 3.5.x essa opção também omite integração. Não chamar apenas `failsafe:integration-test`, pois falhas de asserção são verificadas pelo goal `failsafe:verify`. A passagem por `verify` também empacota a aplicação, com custo adicional em relação à antiga chamada `test`, preservando o ciclo de vida Maven.

Os dois plugins têm `failIfNoTests=true`. Assim, Maven direto falha quando a suíte não possui testes descobertos. O harness detecta ausência de arquivos elegíveis antes de chamar Maven e informa SKIP. No baseline sem unitários, use o script completo ou `-DskipUnitTests=true verify`; não classifique uma omissão como teste aprovado.

## Interpretar resultados

| Resultado | Scripts de suíte | Significado |
|---|---|---|
| PASS | exit `0` | Maven terminou com sucesso e os XML comprovam testes, sem falhas ou omissões |
| SKIP | exit `3` | Não existem classes elegíveis ou há testes ignorados; os contadores mostram eventual execução parcial |
| FAIL | exit `1` | Maven/Docker falhou, relatórios estão ausentes/inválidos ou classes elegíveis produziram zero testes |

Erros de shell também retornam código diferente de zero. Falhas Maven são normalizadas para `1` pelos scripts de suíte, para não confundir um código de erro `3` com SKIP. Docker indisponível é FAIL da etapa; os testes de integração ficam NOT RUN, nunca SKIP silencioso.

Os scripts removem somente os XML gerados da própria suíte antes da execução e leem os contadores `tests`, `failures`, `errors` e `skipped` dos novos relatórios. Não executá-los simultaneamente na mesma árvore, pois compartilham `target/`. O parser espera o formato XML padrão dos plugins fixados; um formato incompatível resulta em FAIL.

`verify.sh` executa build (`clean compile`), unitários, arquitetura, integração e cobertura, sem repetir unitários na etapa de integração. A mutação não faz parte desse fluxo. Em erro, retorna código diferente de zero e resume etapas restantes como NOT RUN. Em SKIP, continua e termina com exit `0`, resumo por etapa e resultado PARCIAL. Esse retorno permite inspecionar a integração mesmo sem unitários; não é evidência de aceitação completa pela [DoD](../engineering/definition-of-done.md).

Somente quando autorizado ou com justificativa comunicada:

```bash
SKIP_INTEGRATION=1 bash scripts/verify.sh
```

A opção produz SKIP explícito de integração e de cobertura (dados de integração ausentes) e resultado PARCIAL. Outros valores além de `0` e `1` são rejeitados.

## Reproduzir PostgreSQL e Mockito

O Testcontainers 2.0.5 usa a imagem oficial obtida de `postgres:18.2`, fixada por digest:

```text
postgres@sha256:a688ae5c99f86c1424e046ace0de890608cc0ddb5ec8ef72a6ff8305fdc8f4d2
```

A referência imutável evita alterações silenciosas da tag, mas exige atualização deliberada para incorporar correções. A versão foi confirmada com `postgres --version` e pelo teste JDBC. O Testcontainers 2.0.x exige declaração de compatibilidade com `postgres` para essa referência; não combinar `:tag@digest`, que seu parser interpreta incorretamente como parte do repository. Ao atualizar, verifique origem, digest e versão, ajuste configuração/asserção e repita integração e isolamento.

Mockito 5.23.0, transitivo dos starters de teste, é carregado com `-javaagent` em ambas as suítes. O goal `dependency:properties` resolve o JAR da dependência efetiva, sem assumir a localização de `.m2`; o caminho é colocado entre aspas para Windows. A propriedade vazia `argLine` permite composição por substituição tardia. O agent JaCoCo usa propriedades próprias (`jacocoUnitArgLine` e `jacocoItArgLine`), compostas na mesma linha, de modo que não sobrescreve `argLine` nem o agent do Mockito. Veja [Quality gates](#quality-gates).

Isso segue a [orientação oficial do Mockito 5.23.0 para Java 21+](https://github.com/mockito/mockito/blob/v5.23.0/mockito-core/src/main/java/org/mockito/Mockito.java): não depender do autoattach dinâmico. A validação isolada usa `-XX:-EnableDynamicAgentLoading` e um mock de classe final. Execuções pela IDE que não deleguem a Maven precisam configurar o mesmo agent no runner. O aviso CDS sobre bootstrap classpath pode permanecer; não é o aviso de carregamento dinâmico e não foi suprimido.

## Verificar o próprio harness

```bash
# Contratos de status e erros, sem Maven/Docker reais.
bash scripts/tests/test-harness.sh

# Maven/Docker reais, em cópia temporária, com as duas convenções coexistindo.
bash scripts/tests/test-maven-isolation.sh

# Maven real, em cópia temporária: quality gates rejeitam violações e aprovam código conforme.
bash scripts/tests/test-quality-gates.sh
```

A primeira verificação cobre ausência de suítes, falhas Maven/Docker, XML ausente/obsoleto, zero testes, testes ignorados, resumo e interrupção de etapas. A segunda verifica Surefire com Docker inacessível, Mockito inline sem attach dinâmico, Failsafe com PostgreSQL sem repetir unitários e uma falha deliberada de IT que deve retornar erro em `verify`. Essa falha esperada só existe na cópia e o script retorna sucesso apenas se ela for rejeitada.

A terceira verificação cria classes de exemplo apenas na cópia e exige que cada gate rejeite violações e aprove código conforme (ver [Quality gates](#quality-gates)).

Fixtures e logs ficam em diretórios únicos sob `target/`, inclusive com espaços nos nomes; `build.sh`/`verify.sh` executam `clean` e os removem. As verificações auxiliares não integram o fluxo padrão e não substituem testes de produto. Para preservar logs do harness completo, use `set -o pipefail` antes de `bash scripts/verify.sh | tee <caminho-fora-de-target>`.

## Quality gates

| Gate | Versão | Meta | Script | Relatórios |
|---|---|---|---|---|
| ArchUnit | 1.5.1 (suporta class files Java 27, major 71) | Nenhuma violação | `test-architecture.sh` | `target/architecture-reports/` |
| JaCoCo | 0.8.16 | LINE ≥ 90% e BRANCH ≥ 90% | `test-coverage.sh` | `target/site/jacoco/index.html` e `jacoco.xml` |
| PIT | 1.30.1, com pitest-junit5-plugin 1.2.3 | Mutation score ≥ 90% | `test-mutation.sh` | `target/pit-reports/index.html` e `mutations.xml` |

As versões são declaradas no `pom.xml`, porque o parent Spring Boot 4.1.2 não as gerencia. O pitest-junit5-plugin usa o `junit-platform-launcher` do projeto (6.0.3, gerenciado pelo BOM), adicionado como dependência de teste.

Todos os scripts retornam `0` PASS, `3` SKIP e `1` FAIL, e imprimem os valores medidos.

### Fluxo rápido e execução explícita

- `verify.sh` inclui arquitetura e cobertura. Mesmo com todas as etapas em PASS, informa PARCIAL para os quality gates completos, porque a mutação fica NOT RUN.
- `test-mutation.sh` é explícito porque executa a suíte unitária uma vez por mutante. Quality gates completos: `bash scripts/verify.sh && bash scripts/test-mutation.sh`.

### ArchUnit

As regras estão em `src/test/java/io/github/wesleyosantos91/catalog/architecture/ArchitectureTest.java` e derivam de [dependency-rules.md](../architecture/dependency-rules.md), [package-conventions.md](../architecture/package-conventions.md) e do [ADR-0001](../architecture/adr/0001-architecture-principles.md):

| Regra | Fonte | Classes elegíveis |
|---|---|---|
| `domain` não depende de Spring | Restrições de domínio; package-conventions | `feature.*.domain` |
| `domain` não depende de HTTP nem de JDBC (`jakarta.servlet`, `java.net.http`, `java.sql`, `javax.sql`) | Restrições de domínio; package-conventions | `feature.*.domain` |
| `domain` não depende de `api`, `persistence`, `messaging` nem `client` | Restrições de domínio | `feature.*.domain` |
| `api` não depende de `persistence` | Controllers não acessam repositories | `feature.*.api` |
| `api` não usa JDBC/SQL | Controllers não executam SQL | `feature.*.api` |
| Producers não dependem de `api` nem de `service` | Integrações | `feature.*.messaging..producer` |
| Nenhuma classe usa JPA (`jakarta.persistence`, Spring Data JPA, Hibernate) | ADR-0001; AGENTS.md | Todo o código de produção |
| Features livres de ciclos | Comunicação entre features | Ao menos duas features |
| Packages internos de cada feature livres de ciclos | "Dependências cíclicas não são permitidas" | Feature com ao menos dois packages internos |
| Feature não acessa a `persistence` de outra | Comunicação entre features | Duas features e alguma `persistence` |

Uma regra sem classes elegíveis é marcada como ignorada (assumption) e torna o resultado SKIP. No scaffold atual, só a regra de JPA executa (sobre `JavaAiEngineeringLabApplication`); as outras nove são SKIP. A direção `api → domain` não está listada em "Dependências permitidas" nem proibida em "Restrições"; por isso não há regra para ela, e o caso aguarda decisão.

### JaCoCo

- Agents em `prepare-agent` (unitários → `target/jacoco-unit.exec`) e `prepare-agent-integration` (integração → `target/jacoco-it.exec`), com `append=false`. A execução de arquitetura não usa o agent, para não sobrescrever os dados unitários.
- `test-coverage.sh` não executa testes. Ele executa `jacoco:merge@coverage-merge`, `jacoco:report@coverage-report` e `jacoco:check@coverage-check` sobre os dados existentes. Execute-o depois das suítes, como faz o `verify.sh`.
- **Exclusão única:** `JavaAiEngineeringLabApplication`, o bootstrap Spring Boot sem regra de negócio. Ela é declarada no relatório, no check e no script.
- SKIP: não há código elegível em `src/main/java`, nenhuma linha foi medida, ou não há branches elegíveis (a meta BRANCH não pode ser comprovada). FAIL: há código elegível sem `.exec`, o relatório está ausente ou o `jacoco:check` rejeitou o limite.

### PIT

- **Escopo (`targetClasses`):** `io.github.wesleyosantos91.catalog.feature.*.domain.*` e `...feature.*.service.*`. São as camadas de regra e coordenação, exercitáveis por testes unitários. `api`, `persistence`, configuração e bootstrap ficam fora, porque são verificados por integração e o PIT não executa `*IT`.
- **Testes:** `*Test`, exceto `*ArchitectureTest`. Formatos XML e HTML, sem timestamp, `mutationThreshold=90` e `failWhenNoMutations=false`. O script diferencia ausência de mutantes (SKIP) de score aprovado (PASS).
- **Mockito:** as JVMs do PIT recebem o agent via `jvmArgs`. O `argLine` do PIT é a propriedade vazia do projeto, então o agent JaCoCo não entra no PIT.

### Validação negativa

`scripts/tests/test-quality-gates.sh` comprovou, na revisão desta etapa:

| Cenário na cópia isolada | Resultado esperado e observado |
|---|---|
| Classe de domain chamando `org.springframework.util.Assert` | Arquitetura FAIL na regra `domainDoesNotDependOnSpring` |
| Domain e service conformes | Arquitetura SKIP: 5 regras executadas e aprovadas, 5 sem classes elegíveis |
| Teste único e insuficiente | Cobertura FAIL (LINE 37,50%, BRANCH 33,33%); mutação FAIL (2 de 8 mutantes detectados) |
| Testes de limites e de ambos os ramos, com mock de classe final | Cobertura PASS (100% e 100%); mutação PASS (8 de 8) |
| JVM de testes unitários | Agents JaCoCo e Mockito carregados simultaneamente |

## Diagnóstico

- **Docker indisponível:** execute `bash scripts/setup.sh`, ative Docker Desktop e repita integração. Não omita a etapa silenciosamente.
- **Classe elegível sem testes:** confira os métodos JUnit e a convenção; Maven deve falhar, em vez de produzir falso PASS.
- **HTTP 401 em resolução de metadados:** verifique repositórios e credenciais do ambiente Maven. Avisos foram observados nesta execução, mas não impediram os artefatos utilizados; não adicionar credenciais ao projeto.
- **Cobertura FAIL sem dados:** execute `bash scripts/verify.sh`; `test-coverage.sh` isolado depende dos `.exec` da execução atual.
- **Mutação lenta ou com timeout:** consulte `target/pit-reports/index.html`; não reduza o threshold nem amplie exclusões.
- **ArchUnit SKIP:** confira em `target/architecture-reports/` quais regras foram ignoradas por ausência de classes elegíveis.
- **Flyway sem migrações:** o baseline ainda não contém migrações de negócio; o aviso foi preservado e não comprova cobertura de migrações futuras.

Referências: [Failsafe 3.5.6 — opções de omissão](https://maven.apache.org/surefire-archives/surefire-3.5.6/maven-failsafe-plugin/examples/skipping-tests.html) e [parser de imagens do Testcontainers 2.0.5](https://github.com/testcontainers/testcontainers-java/blob/2.0.5/core/src/main/java/org/testcontainers/utility/DockerImageName.java).
