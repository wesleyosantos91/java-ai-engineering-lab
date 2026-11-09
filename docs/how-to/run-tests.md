# Executar e diagnosticar testes

Guia operacional para desenvolvedores e agentes. A Etapa 6A separa as suítes e fixa a infraestrutura de integração; não implementa requisitos de produto nem configura JaCoCo, PIT ou ArchUnit. PRD 1.0 e ADRs permanecem preservados.

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
bash scripts/test-integration.sh
bash scripts/verify.sh
```

## Escolher a suíte

| Suíte | Convenção exata em `src/test/java` | Plugin / fase | Relatórios XML e texto |
|---|---|---|---|
| Unitária | `*Test.java` | Surefire 3.5.6 / `test` | `target/surefire-reports/` |
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

`verify.sh` executa build (`clean compile`), unitários e integração, sem repetir unitários na etapa de integração. Em erro, retorna código diferente de zero e resume etapas restantes como NOT RUN. Em SKIP, continua e termina com exit `0`, resumo por etapa e resultado PARCIAL. Esse retorno permite inspecionar a integração mesmo sem unitários; não é evidência de aceitação completa pela [DoD](../engineering/definition-of-done.md).

Somente quando autorizado ou com justificativa comunicada:

```bash
SKIP_INTEGRATION=1 bash scripts/verify.sh
```

A opção produz SKIP explícito de integração e resultado PARCIAL. Outros valores além de `0` e `1` são rejeitados. JaCoCo, PIT e ArchUnit continuam NOT RUN, sem alteração das metas futuras.

## Reproduzir PostgreSQL e Mockito

O Testcontainers 2.0.5 usa a imagem oficial obtida de `postgres:18.2`, fixada por digest:

```text
postgres@sha256:a688ae5c99f86c1424e046ace0de890608cc0ddb5ec8ef72a6ff8305fdc8f4d2
```

A referência imutável evita alterações silenciosas da tag, mas exige atualização deliberada para incorporar correções. A versão foi confirmada com `postgres --version` e pelo teste JDBC. O Testcontainers 2.0.x exige declaração de compatibilidade com `postgres` para essa referência; não combinar `:tag@digest`, que seu parser interpreta incorretamente como parte do repository. Ao atualizar, verifique origem, digest e versão, ajuste configuração/asserção e repita integração e isolamento.

Mockito 5.23.0, transitivo dos starters de teste, é carregado com `-javaagent` em ambas as suítes. O goal `dependency:properties` resolve o JAR da dependência efetiva, sem assumir a localização de `.m2`; o caminho é colocado entre aspas para Windows. A propriedade vazia `argLine` permite composição por substituição tardia. Não foi configurado outro instrumentador.

Isso segue a [orientação oficial do Mockito 5.23.0 para Java 21+](https://github.com/mockito/mockito/blob/v5.23.0/mockito-core/src/main/java/org/mockito/Mockito.java): não depender do autoattach dinâmico. A validação isolada usa `-XX:-EnableDynamicAgentLoading` e um mock de classe final. Execuções pela IDE que não deleguem a Maven precisam configurar o mesmo agent no runner. O aviso CDS sobre bootstrap classpath pode permanecer; não é o aviso de carregamento dinâmico e não foi suprimido.

## Verificar o próprio harness

```bash
# Contratos de status e erros, sem Maven/Docker reais.
bash scripts/tests/test-harness.sh

# Maven/Docker reais, em cópia temporária, com as duas convenções coexistindo.
bash scripts/tests/test-maven-isolation.sh
```

A primeira verificação cobre ausência de suítes, falhas Maven/Docker, XML ausente/obsoleto, zero testes, testes ignorados, resumo e interrupção de etapas. A segunda verifica Surefire com Docker inacessível, Mockito inline sem attach dinâmico, Failsafe com PostgreSQL sem repetir unitários e uma falha deliberada de IT que deve retornar erro em `verify`. Essa falha esperada só existe na cópia e o script retorna sucesso apenas se ela for rejeitada.

Fixtures e logs ficam em diretórios únicos sob `target/`, inclusive com espaços nos nomes; `build.sh`/`verify.sh` executam `clean` e os removem. As verificações auxiliares não integram o fluxo padrão e não substituem testes de produto. Para preservar logs do harness completo, use `set -o pipefail` antes de `bash scripts/verify.sh | tee <caminho-fora-de-target>`.

## Diagnóstico

- **Docker indisponível:** execute `bash scripts/setup.sh`, ative Docker Desktop e repita integração. Não omita a etapa silenciosamente.
- **Classe elegível sem testes:** confira os métodos JUnit e a convenção; Maven deve falhar, em vez de produzir falso PASS.
- **HTTP 401 em resolução de metadados:** verifique repositórios e credenciais do ambiente Maven. Avisos foram observados nesta execução, mas não impediram os artefatos utilizados; não adicionar credenciais ao projeto.
- **Flyway sem migrações:** o baseline ainda não contém migrações de negócio; o aviso foi preservado e não comprova cobertura de migrações futuras.

Referências: [Failsafe 3.5.6 — opções de omissão](https://maven.apache.org/surefire-archives/surefire-3.5.6/maven-failsafe-plugin/examples/skipping-tests.html) e [parser de imagens do Testcontainers 2.0.5](https://github.com/testcontainers/testcontainers-java/blob/2.0.5/core/src/main/java/org/testcontainers/utility/DockerImageName.java).
