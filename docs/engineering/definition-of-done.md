
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
- [ ] Os testes de integração foram executados quando aplicáveis.
- [ ] Os cenários de falha foram considerados.
- [ ] Não existem testes desabilitados sem justificativa.
- [ ] As falhas identificadas foram corrigidas ou documentadas.

### Quality Gates futuros

Após a configuração das ferramentas, serão exigidos:

- JaCoCo: cobertura mínima de 90% das linhas elegíveis.
- JaCoCo: cobertura mínima de 90% dos branches elegíveis.
- PIT: mutation score mínimo de 90%.
- ArchUnit: nenhuma violação das regras arquiteturais definidas.

As exclusões deverão ser explícitas e justificadas.

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

Exceções deverão ser justificadas, documentadas e aprovadas pelo responsável técnico.

Os Quality Gates futuros só se tornam obrigatórios quando as respectivas ferramentas estiverem configuradas e operacionalmente validadas.
