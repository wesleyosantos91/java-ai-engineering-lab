
# Definition of Done (DoD)

## Objetivo

Estabelecer critérios objetivos para considerar uma alteração concluída, independentemente de ter sido implementada manualmente ou com auxílio de agentes de IA.

## 1. Requisitos e comportamento

- [ ] Os critérios de aceitação foram atendidos.
- [ ] Casos de sucesso, erro e situações-limite foram considerados.
- [ ] O comportamento implementado corresponde aos requisitos.
- [ ] Não foram introduzidas funcionalidades fora do escopo aprovado.

## 2. Arquitetura e código

- [ ] As decisões arquiteturais vigentes foram respeitadas.
- [ ] A organização Feature-Based foi preservada.
- [ ] As dependências entre componentes são justificáveis.
- [ ] Não foram introduzidas abstrações desnecessárias.
- [ ] O código é legível e utiliza nomes expressivos.
- [ ] Novas dependências possuem justificativa técnica.

## 3. Testes e qualidade

- [ ] Os testes relevantes foram implementados.
- [ ] Os testes unitários foram executados com sucesso.
- [ ] Os testes de integração foram executados com sucesso quando aplicáveis.
- [ ] Os cenários de falha foram considerados.
- [ ] Não existem testes desabilitados sem justificativa.
- [ ] As falhas identificadas foram investigadas e documentadas, e as obrigações de qualidade pendentes foram resolvidas com evidências.

Um critério de teste obrigatório aplicável só é atendido por resultado satisfatório (`PASS`) com evidência. Documentar uma falha é obrigatório para rastreabilidade, mas não representa aprovação: um `FAIL` impede a conclusão enquanto a obrigação correspondente permanecer pendente. `SKIP` e `NOT RUN` também não satisfazem essa obrigação.

O caminho normal de resolução é investigar a causa, corrigir o código e executar novamente os testes pertinentes, preservando o histórico da falha e da correção. Não é permitido remover ou desabilitar testes, alterar contratos ou reduzir limites apenas para obter sucesso. Uma justificativa de desabilitação não dispensa a obrigação de qualidade aplicável.

### Quality Gates

As ferramentas estão configuradas no `pom.xml` e no harness ([guia de testes](../how-to/run-tests.md#quality-gates)). Uma vez obrigatórios, conforme a condição ao final deste documento, serão exigidos:

- JaCoCo: cobertura mínima de 90% das linhas elegíveis.
- JaCoCo: cobertura mínima de 90% dos branches elegíveis.
- PIT: mutation score mínimo de 90%.
- ArchUnit: nenhuma violação das regras arquiteturais definidas.

As exclusões deverão ser explícitas e justificadas.

Ausência de código, classes, branches ou mutantes elegíveis resulta em `SKIP` e não satisfaz o gate. A mutação não integra o `verify.sh` e exige execução explícita de `scripts/test-mutation.sh`.

Cobertura não substitui testes comportamentais relevantes.

## 4. Persistência

Quando houver alterações no banco de dados:

- [ ] As mudanças de esquema foram versionadas com Flyway.
- [ ] As migrações foram testadas.
- [ ] As transações foram avaliadas.
- [ ] As consultas foram analisadas quanto a desempenho.
- [ ] Não existem credenciais armazenadas no código.

## 5. Segurança e observabilidade

- [ ] Dados sensíveis não são expostos em logs.
- [ ] Erros possuem tratamento adequado.
- [ ] Logs relevantes fornecem contexto para investigação.
- [ ] Métricas e traces foram avaliados quando aplicáveis.
- [ ] Não foram introduzidas vulnerabilidades conhecidas sem tratamento.

## 6. Performance

Quando houver impacto relevante:

- [ ] Foram definidos indicadores de desempenho.
- [ ] O ambiente e a carga de teste foram documentados.
- [ ] Foram coletadas evidências antes e depois da mudança.
- [ ] Trade-offs de CPU, memória e latência foram avaliados.

## 7. AI-First e rastreabilidade

Quando agentes de IA participarem:

- [ ] O escopo autorizado foi respeitado.
- [ ] As decisões relevantes foram explicadas.
- [ ] Nenhum comando destrutivo foi executado sem autorização.
- [ ] Não foram inventados resultados de testes ou benchmarks.
- [ ] As verificações realmente executadas foram identificadas.
- [ ] Alterações arquiteturais relevantes receberam revisão humana.
- [ ] As limitações e pendências foram comunicadas.

## 8. Entrega

- [ ] A documentação relevante foi atualizada.
- [ ] O commit possui mensagem descritiva.
- [ ] O pull request descreve objetivo, alterações e validações.
- [ ] Os critérios de revisão foram atendidos.
- [ ] A alteração está pronta para integração.

## Política de exceções

Uma alteração que não cumpra algum critério obrigatório não deverá ser declarada concluída.

Somente o responsável técnico humano pode aprovar uma exceção; o agente pode propô-la e registrar a decisão verificável, sem concedê-la por conta própria. A aprovação de exceção é distinta da revisão humana de conclusão e não reclassifica `FAIL`, `SKIP` ou `NOT RUN` como `PASS`.

Exceções podem tratar condições documentais ou operacionais justificáveis, como o adiamento de uma atividade não obrigatória. Elas não dispensam testes obrigatórios aplicáveis, não autorizam reduzir limites para obter aprovação nem afastam requisitos essenciais do contrato funcional ou sua comprovação. Uma falha que comprometa esses requisitos exige correção; mudanças de contrato seguem seu processo próprio de autorização, sem alterar requisitos congelados de experimentos por meio de exceção.

Cada exceção deve registrar:

1. O critério exato afetado, sua fonte e o efeito solicitado, explicitando se existe obrigação pendente.
2. A justificativa de necessidade e as evidências da situação excepcional.
3. O risco residual expressamente aceito e as medidas compensatórias adotadas; se inexistentes, registrar essa ausência e sua justificativa.
4. O plano de resolução ou reavaliação, com responsável e prazo ou condição objetiva para revisão.
5. A decisão, o responsável técnico que a aprovou, a data quando disponível e a referência verificável; informações indisponíveis devem ser identificadas, nunca inventadas.

Registre a exceção nas seções de evidências e aprovação da especificação existente, conforme o [template de feature](../features/TEMPLATE.md), ou no registro versionado da tarefa quando não houver especificação. Vincule a decisão e sua evidência à pendência e ao relatório de revisão; uma aprovação genérica sem esses registros não constitui exceção válida.

Mesmo aprovada e documentada, uma exceção não permite declarar a feature Concluída enquanto algum critério obrigatório permanecer pendente. O checklist deve manter explícito o que não foi atendido. Uma execução parcial pode ser autorizada e registrada, mas continua parcial; não demonstra aceitação completa. Se não houver obrigações pendentes, a conclusão ainda depende das demais condições e da revisão humana previstas no [catálogo](../features/README.md), sem criar um estado adicional de feature.

Os Quality Gates só se tornam obrigatórios quando as respectivas ferramentas estiverem configuradas e operacionalmente validadas. A configuração da Etapa 6B foi validada em cópias isoladas com código de exemplo; o reconhecimento da validação operacional depende de revisão humana registrada.
