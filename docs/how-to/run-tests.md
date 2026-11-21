# Executar e diagnosticar testes

Guia operacional para desenvolvedores e agentes. A Etapa 6A separa as suítes e fixa a infraestrutura de integração; a Etapa 6B configura os quality gates JaCoCo, ArchUnit e PIT. Nenhuma delas implementa requisitos de produto. PRD 1.0 e ADRs permanecem preservados.

## Pré-requisitos

- Windows 11 com Git Bash, ou ambiente Bash compatível.
- Java no PATH igual ou superior ao `java.version` do pom do app (`setup.sh` compara); baseline deste repositório: Java 27, Temurin 27+35.
- Maven Wrapper versionado, que resolve Maven 3.10.0; não é necessário Maven global.
- Docker Desktop funcional com contêineres Linux para integração.
- Acesso aos repositórios Maven e Docker na primeira resolução dos artefatos.

Execute os comandos a partir da raiz. Os scripts também funcionam quando invocados pelo caminho absoluto de outro diretório, incluindo caminhos com espaços.

```bash
bash scripts/setup.sh
bash scripts/test/unit.sh
bash scripts/test/architecture.sh
bash scripts/test/integration.sh
bash scripts/quality/coverage.sh     # após as suítes; não executa testes
bash scripts/verify.sh            # configuração de agentes, build, unitários, arquitetura, integração e cobertura
bash scripts/quality/mutation.sh     # explícito; fora do verify.sh
```

## Onde o harness procura o projeto (`.harness`)

Os scripts ficam na raiz, mas o Maven executa no diretório do app, declarado no arquivo `.harness` da raiz (lido por `scripts/lib/app.sh` como chave=valor, sem executar código):

| Chave | Valores | Efeito |
|---|---|---|
| `APP_DIR` | Caminho relativo, sem `..` (padrão `.`) | Onde ficam `pom.xml`, `mvnw`, `src/` e `target/`. Neste repositório, `.`; em projetos criados pelo kit ou pelo seed, sempre `app` ([layout do repositório](../architecture/repository-layout.md)) |
| `QUALITY_GATES` | `required` (padrão) ou `optional` | Gate não configurado no pom do app (sem a execução `architecture`, o Failsafe, o JaCoCo `coverage-check`, o `pitest-maven` ou as propriedades `app.*`): `required` = FAIL; `optional` = SKIP, com o motivo e o [guia para ativar](enable-quality-gates.md) |

| `REPOSITORY_ROLE` | `project` (padrão) ou `reference` | Só `reference` (este repositório) aceita `APP_DIR` diferente de `app` |

Os caminhos `target/...` deste guia são relativos ao `APP_DIR`. O `check-config.sh` rejeita chaves e valores inválidos e, em projetos, um `APP_DIR` diferente de `app`. O `unit.sh` avisa quando há classes `*Tests` (padrão do Spring Initializr), que a convenção não executa.

## Escolher a suíte

| Suíte | Convenção exata em `src/test/java` | Plugin / fase | Relatórios XML e texto |
|---|---|---|---|
| Unitária | `*Test.java`, exceto `*ArchitectureTest.java` | Surefire 3.5.6 / `test` (execução `default-test`) | `target/surefire-reports/` |
| Arquitetura | `*ArchitectureTest.java` | Surefire 3.5.6 / `surefire:test@architecture`, sem fase | `target/architecture-reports/` |
| Integração | `*IT.java` | Failsafe 3.5.6 / `integration-test` e `verify` | `target/failsafe-reports/` |

As versões dos plugins são gerenciadas pelo parent Spring Boot 4.1.2. Não usar as convenções padrão alternativas `*Tests`, `Test*` ou `*ITCase` para novos testes: os includes do POM são explícitos. Classes auxiliares, como `TestcontainersConfiguration` e a aplicação de desenvolvimento `TestJavaAiEngineeringLabApplication`, não são testes executáveis.

Unitários não devem usar `@SpringBootTest`, importar a configuração de contêineres nem depender de Docker. O teste de contexto foi renomeado para `JavaAiEngineeringLabApplicationIT`; ele inicializa PostgreSQL com `@ServiceConnection` e verifica `SHOW server_version` por JDBC. Os testes de produto da [FEAT-0001](../features/FEAT-0001-create-product/spec.md) são `*Test` em `feature/product/domain` e `feature/product/service` e `ProductCreationIT`/`ProductConcurrencyIT`, com HTTP real e PostgreSQL. <!-- kit:replace-line: Unitários não devem usar `@SpringBootTest`, importar a configuração de contêineres nem depender de Docker. O teste de contexto (`*ApplicationIT`) inicializa PostgreSQL com `@ServiceConnection` e verifica `SHOW server_version` por JDBC. -->

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

`verify.sh` executa a verificação da configuração de agentes (`agents/check-config.sh`, sem Maven; ver [context engineering](../ai/context-engineering.md#harness-da-configuração)), build (`clean compile`), unitários, arquitetura, integração e cobertura, sem repetir unitários na etapa de integração. A mutação não faz parte desse fluxo. Em erro, retorna código diferente de zero e resume etapas restantes como NOT RUN. Em SKIP, continua e termina com exit `0`, resumo por etapa e resultado PARCIAL. Esse retorno permite inspecionar a integração mesmo sem unitários; não é evidência de aceitação completa pela [DoD](../engineering/definition-of-done.md).

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

## Verificar o PRD e as pendências do projeto

```bash
bash scripts/agents/list-pending.sh           # todos os campos a preencher, por responsável
bash scripts/product/check-prd.sh             # docs/product/prd.md
bash scripts/product/check-prd.sh <arquivo>   # outro PRD
```

O `list-pending.sh` percorre os documentos Markdown (exceto templates, stubs `.claude/`, o app, blocos de código e comentários HTML) e agrupa por responsável os campos `[PREENCHER-NEGÓCIO: ...]`, `[PREENCHER-ENGENHARIA: ...]` e os sem responsável. Retorna `0` sem pendências e `3` (SKIP) com pendências.

Lista os campos `[PREENCHER-NEGÓCIO: ...]`, `[PREENCHER-ENGENHARIA: ...]` e `[PREENCHER...]` restantes, por responsável, seção e linha; campos citados em código (entre crases) são exemplos e não contam. Retorna `0` sem pendências, `3` (SKIP) com o PRD ausente ou em elaboração e `1` quando o Status do cabeçalho começa com "Aprovado" e ainda há campos pendentes ou nenhum critério `### CA-NN`. O `agents/check-config.sh` só falha neste último caso, para que um PRD em elaboração não bloqueie o fluxo.

## Verificar o próprio harness

```bash
# Contratos de status e erros, sem Maven/Docker reais.
bash scripts/harness-tests/harness.sh

# Maven/Docker reais, em cópia temporária, com as duas convenções coexistindo.
bash scripts/harness-tests/maven-isolation.sh

# Maven real, em cópia temporária: quality gates rejeitam violações e aprovam código conforme.
bash scripts/harness-tests/quality-gates.sh

# Sem Maven/Docker, em cópia temporária: check de agentes, stubs .claude/skills e hook do Claude.
bash scripts/harness-tests/agent-config.sh

# Repositório Git temporário: mensagens de commit, coautoria, --range e hooks instalados.
bash scripts/harness-tests/git-hooks.sh
```

O exportador do kit tem teste próprio, em destinos temporários: `bash scripts/harness-tests/export-kit.sh` (kit só de configuração, seed e `init-project.sh` num projeto criado do seed). <!-- kit:omit-line -->

A primeira verificação simula `agents/check-config.sh`, que tem teste próprio (a quarta verificação), e cobre ausência de suítes, falhas Maven/Docker, XML ausente/obsoleto, zero testes, testes ignorados, resumo e interrupção de etapas. A segunda verifica Surefire com Docker inacessível, Mockito inline sem attach dinâmico, Failsafe com PostgreSQL sem repetir unitários e uma falha deliberada de IT que deve retornar erro em `verify`. Essa falha esperada só existe na cópia e o script retorna sucesso apenas se ela for rejeitada.

A terceira verificação cria classes de exemplo apenas na cópia e exige que cada gate rejeite violações e aprove código conforme (ver [Quality gates](#quality-gates)).

Fixtures e logs ficam em diretórios únicos sob `target/`, inclusive com espaços nos nomes; `build/compile.sh`/`verify.sh` executam `clean` e os removem. As verificações auxiliares não integram o fluxo padrão e não substituem testes de produto. Para preservar logs do harness completo, use `set -o pipefail` antes de `bash scripts/verify.sh | tee <caminho-fora-de-target>`.

## Quality gates

| Gate | Versão | Meta | Script | Relatórios |
|---|---|---|---|---|
| ArchUnit | 1.5.1 (suporta class files Java 27, major 71) | Nenhuma violação | `test/architecture.sh` | `target/architecture-reports/` |
| JaCoCo | 0.8.16 | LINE ≥ 90% e BRANCH ≥ 90% | `quality/coverage.sh` | `target/site/jacoco/index.html` e `jacoco.xml` |
| PIT | 1.30.1, com pitest-junit5-plugin 1.2.3 | Mutation score ≥ 90% | `quality/mutation.sh` | `target/pit-reports/index.html` e `mutations.xml` |

As versões são declaradas no `pom.xml`, porque o parent Spring Boot 4.1.2 não as gerencia. O pitest-junit5-plugin usa o `junit-platform-launcher` do projeto (6.0.3, gerenciado pelo BOM), adicionado como dependência de teste.

Todos os scripts retornam `0` PASS, `3` SKIP e `1` FAIL, e imprimem os valores medidos.

### Fluxo rápido e execução explícita

- `verify.sh` inclui arquitetura e cobertura. Mesmo com todas as etapas em PASS, informa PARCIAL para os quality gates completos, porque a mutação fica NOT RUN.
- `quality/mutation.sh` é explícito porque executa a suíte unitária uma vez por mutante. Quality gates completos: `bash scripts/verify.sh && bash scripts/quality/mutation.sh`.

### ArchUnit

As regras estão em `src/test/java/io/github/wesleyosantos91/catalog/architecture/ArchitectureTest.java` e derivam de [dependency-rules.md](../architecture/dependency-rules.md), [package-conventions.md](../architecture/package-conventions.md) e do [ADR-0001](../architecture/adr/0001-architecture-principles.md):

| Regra | Fonte | Classes elegíveis |
|---|---|---|
| `domain` não depende de Spring | Restrições de domínio; package-conventions | `feature.*.domain` |
| `domain` não depende de HTTP nem de JDBC (`jakarta.servlet`, `java.net.http`, `java.sql`, `javax.sql`) | Restrições de domínio; package-conventions | `feature.*.domain` |
| `domain` não depende de `api`, `persistence`, `messaging` nem `client` | Restrições de domínio | `feature.*.domain` |
| `api` não depende de `persistence` | Controllers não acessam repositories | `feature.*.api` |
| `api` não usa JDBC/SQL | Controllers não executam SQL | `feature.*.api` |
| `api` não depende de `domain` | `api` depende somente de `service` (dependency-rules, ADR-0003) | `feature.*.api` |
| Producers não dependem de `api` nem de `service` | Integrações | `feature.*.messaging..producer` |
| Nenhuma classe usa JPA (`jakarta.persistence`, Spring Data JPA, Hibernate) | ADR-0001; AGENTS.md | Todo o código de produção |
| Features livres de ciclos | Comunicação entre features | Ao menos duas features |
| Packages internos de cada feature livres de ciclos | "Dependências cíclicas não são permitidas" | Feature com ao menos dois packages internos |
| Feature não acessa a `persistence` de outra | Comunicação entre features | Duas features e alguma `persistence` |

Uma regra sem classes elegíveis é ignorada com o marcador `[N/A]` na premissa e reportada como **não aplicável**: não conta como SKIP e aparece no resumo (`N/A=n`). A arquitetura é PASS quando nenhuma regra aplicável falha e ao menos uma executa; se todas forem N/A, é SKIP ([ADR-0003](../architecture/adr/0003-test-suites-and-quality-gates.md)). Com a FEAT-0001, 8 regras executam e passam. As 3 N/A dependem de duas features (ciclos entre features e acesso à `persistence` de outra) ou de código de mensageria (producers). <!-- kit:replace-line: Uma regra sem classes elegíveis é ignorada com o marcador `[N/A]` na premissa e reportada como **não aplicável**: não conta como SKIP e aparece no resumo (`N/A=n`). A arquitetura é PASS quando nenhuma regra aplicável falha e ao menos uma executa; se todas forem N/A, é SKIP ([ADR-0003](../architecture/adr/0003-test-suites-and-quality-gates.md)). -->

### JaCoCo

- Agents em `prepare-agent` (unitários → `target/jacoco-unit.exec`) e `prepare-agent-integration` (integração → `target/jacoco-it.exec`), com `append=false`. A execução de arquitetura não usa o agent, para não sobrescrever os dados unitários.
- `quality/coverage.sh` não executa testes. Ele executa `jacoco:merge@coverage-merge`, `jacoco:report@coverage-report` e `jacoco:check@coverage-check` sobre os dados existentes. Execute-o depois das suítes, como faz o `verify.sh`.
- **Exclusão única:** `JavaAiEngineeringLabApplication`, o bootstrap Spring Boot sem regra de negócio. Ela é declarada no relatório, no check e no script.
- SKIP: não há código elegível em `src/main/java`, nenhuma linha foi medida, ou não há branches elegíveis (a meta BRANCH não pode ser comprovada). FAIL: há código elegível sem `.exec`, o relatório está ausente ou o `jacoco:check` rejeitou o limite.

### PIT

- **Escopo (`targetClasses`):** `io.github.wesleyosantos91.catalog.feature.*.domain.*` e `...feature.*.service.*`. São as camadas de regra e coordenação, exercitáveis por testes unitários. `api`, `persistence`, configuração e bootstrap ficam fora, porque são verificados por integração e o PIT não executa `*IT`.
- **Testes:** `*Test`, exceto `*ArchitectureTest`. Formatos XML e HTML, sem timestamp, `mutationThreshold=90` e `failWhenNoMutations=false`. O script diferencia ausência de mutantes (SKIP) de score aprovado (PASS).
- **Mockito:** as JVMs do PIT recebem o agent via `jvmArgs`. O `argLine` do PIT é a propriedade vazia do projeto, então o agent JaCoCo não entra no PIT.

### Validação negativa

`scripts/harness-tests/quality-gates.sh` comprovou, na revisão desta etapa:

| Cenário na cópia isolada | Resultado esperado e observado |
|---|---|
| Classe de domain chamando `org.springframework.util.Assert` | Arquitetura FAIL na regra `domainDoesNotDependOnSpring` |
| Domain e service conformes | Arquitetura SKIP: 5 regras executadas e aprovadas, 5 sem classes elegíveis |
| Teste único e insuficiente | Cobertura FAIL (LINE 37,50%, BRANCH 33,33%); mutação FAIL (2 de 8 mutantes detectados) |
| Testes de limites e de ambos os ramos, com mock de classe final | Cobertura PASS (100% e 100%); mutação PASS (8 de 8) |
| JVM de testes unitários | Agents JaCoCo e Mockito carregados simultaneamente |

## Performance

Smoke de disponibilidade com [k6](https://grafana.com/docs/k6/latest/), em execução explícita, fora do `verify.sh`. Ele exige a aplicação já em execução:

```bash
# Terminal 1: aplicação com PostgreSQL via Testcontainers (exige Docker).
bash ./mvnw spring-boot:test-run

# Terminal 2: smoke contra http://localhost:8080 (BASE_URL e DURATION opcionais).
bash scripts/performance/smoke.sh
BASE_URL=http://localhost:9090 DURATION=30s bash scripts/performance/smoke.sh
```

| Resultado | Condição |
|---|---|
| PASS (`0`) | Todas as requisições a `/actuator/health` retornaram 200 com `status` `UP`; resumo em `target/performance/smoke-summary.json` |
| FAIL (`1`) | k6 ou curl ausente, aplicação inacessível (smoke NOT RUN), threshold violado ou resumo ausente |

O cenário `tests/performance/k6/smoke.js` usa 1 VU e só thresholds de disponibilidade (`http_req_failed` = 0 e `checks` = 100%). Latências e vazão impressas pelo k6 são informativas: o [PRD](../product/prd.md) só admite metas de desempenho definidas por protocolo reproduzível. Cenários de load e stress serão criados com a primeira feature com endpoint ([skill performance-optimization](../../.agents/skills/performance-optimization/SKILL.md)).

Encerre a aplicação com `Ctrl+C` no terminal em que ela foi iniciada. No Windows, matar apenas o processo `bash`/`mvnw` deixa a JVM filha escutando na porta 8080 ([LL-0006](../ai/lessons-learned.md#ll-0006--no-windows-encerrar-o-mvnw-não-encerra-a-jvm-da-aplicação)). <!-- kit:replace-line: Encerre a aplicação com `Ctrl+C` no terminal em que ela foi iniciada. No Windows, matar apenas o processo `bash`/`mvnw` deixa a JVM filha escutando na porta 8080. -->

## Segredos e commits

```bash
bash scripts/security/scan-secrets.sh            # histórico Git e árvore de trabalho
bash scripts/security/scan-secrets.sh --staged   # só o diff preparado (usado pelo pre-commit)
bash scripts/git/check-commit-msg.sh --range develop..HEAD
bash scripts/git/install-hooks.sh                # commit-msg e pre-commit; --uninstall, --status
```

A varredura usa o [gitleaks](https://github.com/gitleaks/gitleaks) local ou, na falta dele, a imagem oficial `ghcr.io/gitleaks/gitleaks:v8.30.1` fixada por digest, via Docker. Usa as regras padrão e o `.gitleaks.toml`, que ignora apenas `target/` e `.idea/`. Os valores encontrados são ocultados na saída (`--redact`). Resultados: `0` PASS, `3` SKIP (sem gitleaks e sem Docker), `1` FAIL (achado ou erro). Um segredo exposto deve ser revogado; removê-lo do histórico não basta.

## Diagnóstico

- **Docker indisponível:** execute `bash scripts/setup.sh`, ative Docker Desktop e repita integração. Não omita a etapa silenciosamente. No Windows, `docker` no PATH não garante daemon ativo: se `docker info` mostrar o cliente mas falhar em `npipe:////./pipe/dockerDesktopLinuxEngine`, o Docker Desktop está parado ([LL-0002](../ai/lessons-learned.md#ll-0002--docker-desktop-parado-aparece-como-fail-da-integração)). <!-- kit:replace-line: - **Docker indisponível:** execute `bash scripts/setup.sh`, ative Docker Desktop e repita integração. Não omita a etapa silenciosamente. No Windows, `docker` no PATH não garante daemon ativo: se `docker info` mostrar o cliente mas falhar em `npipe:////./pipe/dockerDesktopLinuxEngine`, o Docker Desktop está parado. -->
- **Classe elegível sem testes:** confira os métodos JUnit e a convenção; Maven deve falhar, em vez de produzir falso PASS.
- **HTTP 401 em resolução de metadados:** verifique repositórios e credenciais do ambiente Maven. Avisos foram observados nesta execução, mas não impediram os artefatos utilizados; não adicionar credenciais ao projeto.
- **Cobertura FAIL sem dados:** execute `bash scripts/verify.sh`; `quality/coverage.sh` isolado depende dos `.exec` da execução atual.
- **Mutação lenta ou com timeout:** consulte `target/pit-reports/index.html`; não reduza o threshold nem amplie exclusões.
- **ArchUnit SKIP:** confira em `target/architecture-reports/` quais regras foram ignoradas por ausência de classes elegíveis.
- **Flyway sem migrações:** o baseline ainda não contém migrações de negócio; o aviso foi preservado e não comprova cobertura de migrações futuras.

Referências: [Failsafe 3.5.6 — opções de omissão](https://maven.apache.org/surefire-archives/surefire-3.5.6/maven-failsafe-plugin/examples/skipping-tests.html) e [parser de imagens do Testcontainers 2.0.5](https://github.com/testcontainers/testcontainers-java/blob/2.0.5/core/src/main/java/org/testcontainers/utility/DockerImageName.java).
