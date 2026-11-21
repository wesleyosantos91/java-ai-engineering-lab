# Ativar os quality gates no app

O kit de configuração não altera o projeto Maven em `app/`. Sem a configuração dos gates no `app/pom.xml`, o harness roda com `QUALITY_GATES=optional` (`.harness`): build e suítes executam, e cada gate não configurado retorna **SKIP** com o motivo. SKIP não é PASS, e o `verify.sh` termina PARCIAL ([ADR-0003](../architecture/adr/0003-test-suites-and-quality-gates.md)).

Este guia descreve o que adicionar para que JaCoCo, PIT e ArchUnit executem de fato. A referência completa e verificada é o `pom.xml` deste repositório, de onde o exportador gera, no projeto de destino, os [blocos prontos](#blocos-prontos-para-este-projeto) com o pacote e a classe do projeto. <!-- kit:replace-line: Este guia descreve o que adicionar para que JaCoCo, PIT e ArchUnit executem de fato. Os [blocos prontos](#blocos-prontos-para-este-projeto) no fim deste guia já vêm com o pacote e a classe deste projeto: copie-os em vez de reescrevê-los. -->

## O que o harness procura

| Gate | Script | Exige em `app/pom.xml` | Sem isso |
|---|---|---|---|
| Unitários | `scripts/test/unit.sh` | Surefire (padrão do Spring Boot); classes `*Test` | Classes `*Tests` (padrão do Initializr) não executam; o script avisa |
| Arquitetura | `scripts/test/architecture.sh` | Execução Surefire `<id>architecture</id>`; classe `*ArchitectureTest` | SKIP (`optional`) ou FAIL (`required`) |
| Integração | `scripts/test/integration.sh` | `maven-failsafe-plugin` e propriedade `skipUnitTests`; classes `*IT` | SKIP ou FAIL |
| Cobertura | `scripts/quality/coverage.sh` | JaCoCo com as execuções `prepare-unit-agent`, `prepare-integration-agent`, `coverage-merge`, `coverage-report` e `coverage-check`; propriedade `app.mainClass` | SKIP ou FAIL |
| Mutação | `scripts/quality/mutation.sh` | `pitest-maven` com `targetClasses` em `feature/*/domain` e `feature/*/service`; propriedade `app.basePath` | SKIP ou FAIL |

## Passos

1. **Propriedades** em `<properties>`: `app.basePackage`, `app.basePath` e `app.mainClass` (pacote e classe `@SpringBootApplication` do app), `skipUnitTests` (`false`), `argLine` vazia e as versões de JaCoCo, PIT e ArchUnit.
2. **Plugins:** `maven-dependency-plugin` (execução `resolve-test-agent`, para o agent do Mockito), Surefire (`default-test` e `architecture`), Failsafe, JaCoCo e PIT, com as metas LINE ≥ 90%, BRANCH ≥ 90% e mutation score ≥ 90%.
3. **Dependências de teste:** ArchUnit, Testcontainers (PostgreSQL) e `junit-platform-launcher`.
4. **Classes de teste** em `app/src/test/java/<pacote>/`: `architecture/ArchitectureTest.java`, `TestcontainersConfiguration.java`, `<Main>IT.java` e `Test<Main>.java`, adaptadas do seed.
5. **Convenção de nomes:** renomeie `*Tests` para `*Test` (unitários) ou `*IT` (integração).
6. Troque `QUALITY_GATES=optional` por `QUALITY_GATES=required` no `.harness`. A partir daí, um gate não configurado reprova o `verify.sh`.
7. Verifique com `bash scripts/verify.sh` e `bash scripts/quality/mutation.sh`. A capacidade de rejeitar violações pode ser provada com `bash scripts/harness-tests/quality-gates.sh`.

Mudanças no `app/pom.xml` são mudanças de build: exigem autorização, e as metas não podem ser reduzidas para obter aprovação (AGENTS.md, seção 6).
