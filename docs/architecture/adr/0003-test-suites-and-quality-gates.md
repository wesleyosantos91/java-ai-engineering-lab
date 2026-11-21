# ADR-0003: Suítes de teste e quality gates

- **Status:** Proposta
- **Data:** 2026-11-20
- **Responsável pela decisão:** Wesley Oliveira Santos
- **Substitui:** —
- **Substituído por:** —
- **Relacionados:** [ADR-0001](0001-architecture-principles.md), seção Qualidade (complementa "configurar futuramente JaCoCo, PIT e testes arquiteturais")

## Contexto

O ADR-0001 previu a configuração futura de JaCoCo, PIT e testes arquiteturais. As Etapas 6A e 6B implementaram essa configuração no `pom.xml` e no harness `scripts/`. As decisões resultantes estavam registradas apenas no `AGENTS.md` e no [guia de testes](../../how-to/run-tests.md), sem histórico de alternativas nem consequências.

Este ADR registra retroativamente decisões já implementadas. Ele não introduz mudança de comportamento.

## Decisão

### Suítes

- **Unitária:** classes `*Test.java` executadas pelo Surefire na fase `test`, sem contexto Spring e sem Docker.
- **Arquitetura:** classes `*ArchitectureTest.java` no package `io.github.wesleyosantos91.catalog.architecture`, executadas pelo Surefire na execução dedicada `surefire:test@architecture`, fora da contagem de unitários.
- **Integração:** classes `*IT.java` executadas pelo Failsafe em `integration-test` e `verify`, com Testcontainers.
- Convenções alternativas (`*Tests`, `Test*`, `*ITCase`) não são aceitas.
- Para executar só a integração, usa-se `-DskipUnitTests=true verify`, nunca `-DskipTests`.
- O Mockito é carregado como `-javaagent` em ambas as suítes, sem attach dinâmico, conforme a orientação do Mockito para Java 21+.
- A imagem do PostgreSQL (18.2) é fixada por digest e só é atualizada por mudança deliberada e verificada.

### Quality gates

| Gate | Meta | Escopo elegível | Fluxo |
|---|---|---|---|
| ArchUnit | Nenhuma violação | Classes de produção, por regra derivada dos documentos de arquitetura | `verify.sh` |
| JaCoCo | LINE ≥ 90% e BRANCH ≥ 90% | Produção, exceto `JavaAiEngineeringLabApplication` | `verify.sh` |
| PIT | Mutation score ≥ 90% | `feature.*.domain` e `feature.*.service`, exercitados por `*Test` | Execução explícita |

### Semântica de resultados

- Os scripts retornam `0` PASS, `3` SKIP e `1` FAIL.
- A ausência de classes, código, branches ou mutantes elegíveis é SKIP, nunca PASS.
- `verify.sh` com SKIP termina com resultado PARCIAL.
- **Exceção, somente para ArchUnit:** uma regra cuja pré-condição estrutural não existe (por exemplo, ciclos entre features com uma única feature, ou producers sem código de mensageria) é **N/A** (não aplicável), marcada por `[N/A]` na premissa do teste. N/A não conta como SKIP, mas aparece no resumo. A arquitetura só é PASS se nenhuma regra aplicável falhar e **ao menos uma regra executar**; com todas as regras N/A, o resultado é SKIP. A suposição de uma regra ser trivialmente verdadeira fica explícita no relatório, sem tornar o fluxo PARCIAL para sempre.

### Fronteira `api → service`

Dentro de uma feature, `api` depende somente de `service`, nunca de `domain` (decisão do responsável em 2026-11-20, aplicada na FEAT-0001). A regra ArchUnit `apiDoesNotDependOnDomain` a protege, e `harness-tests/quality-gates.sh` prova que uma violação é rejeitada. <!-- kit:replace-line: Dentro de uma feature, `api` depende somente de `service`, nunca de `domain`. A regra ArchUnit `apiDoesNotDependOnDomain` a protege, e `harness-tests/quality-gates.sh` prova que uma violação é rejeitada. -->

## Alternativas consideradas

- **Convenções padrão do Surefire/Failsafe (`*Tests`, `Test*`, `*ITCase`):** não adotadas. Includes explícitos evitam execução duplicada ou acidental.
- **ArchUnit dentro da suíte unitária:** não adotado. Mistura regras arquiteturais com a contagem e a cobertura de unitários.
- **PIT no fluxo padrão:** não adotado. O custo é proporcional ao número de mutantes. Fica como execução explícita, exigida para os quality gates completos.
- **PIT sobre `api` e `persistence`:** não adotado. Essas camadas são verificadas por integração, que o PIT não executa.
- **Tratar regras sem classes elegíveis como SKIP permanente:** não adotada (revisão de 2026-11-20). Deixava o `verify.sh` PARCIAL indefinidamente por regras que só se aplicam a estruturas inexistentes, banalizando o PARCIAL.
- **Tratar regras sem classes elegíveis como PASS silencioso:** não adotada. Esconde a suposição; o N/A explícito a mantém visível.
- **Tag `postgres:18.2` sem digest:** não adotada. A tag é mutável e compromete a reprodutibilidade.

## Consequências positivas

- Resultados reproduzíveis e sem falso PASS.
- Separação clara de custo entre os fluxos rápido e completo.
- Metas verificáveis por agentes e pessoas com os mesmos comandos.

## Consequências negativas

- A integração passa por `verify` e empacota a aplicação, com custo maior.
- Exclusões e escopos aparecem no `pom.xml` e nos scripts e precisam ficar sincronizados.
- A atualização da imagem do PostgreSQL é manual.

## Validação

`bash scripts/harness-tests/harness.sh`, `bash scripts/harness-tests/maven-isolation.sh` e `bash scripts/harness-tests/quality-gates.sh`.

## Revisão da decisão

Revisar ao introduzir novas camadas elegíveis (por exemplo, `messaging`), ao mudar metas ou escopos, ou quando a duração da mutação inviabilizar a execução explícita.
