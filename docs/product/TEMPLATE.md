# PRD-NNN — [PREENCHER: nome do produto]

> Modelo de Product Requirements Document. Copie para `docs/product/prd.md` (ou `prd-NNN-*.md`) e substitua os campos `[PREENCHER: ...]`. Use `Não se aplica — justificativa` quando pertinente. Um PRD só vira contrato depois de aprovado por revisão humana (seção 14); agentes não alteram PRDs aprovados.

**Projeto:** [PREENCHER]\
**Versão do documento:** 0.1\
**Status:** Rascunho\
**Responsável pela aprovação:** [PREENCHER]

## 1. Contexto

[PREENCHER: problema de negócio, público, motivação e restrições conhecidas. Diferencie fatos de hipóteses.]

## 2. Objetivos

- [PREENCHER: resultado esperado e verificável.]

## 3. Escopo funcional

O sistema deverá permitir:

- [PREENCHER: capacidade funcional.]

## 4. Modelo de dados e regras de domínio

| Campo | Tipo lógico | Regra |
|---|---|---|
| [PREENCHER] | [PREENCHER] | [PREENCHER: obrigatoriedade, formato, limites, normalização, unicidade] |

[PREENCHER: regras de normalização, validação e invariantes por campo, sem ambiguidade: dois leitores devem derivar os mesmos testes.]

## 5. Contrato de interface

[PREENCHER: rotas ou operações, métodos, status de sucesso, parâmetros, paginação e ordenação. Para APIs HTTP, inclua uma tabela de operações e o comportamento de cada uma.]

## 6. Representação e erros

[PREENCHER: campos aceitos e retornados, rejeição de campos desconhecidos, tipos JSON exigidos, formato de erro (por exemplo `ProblemDetail`, RFC 9457) e códigos de erro estáveis.]

## 7. Integridade e concorrência

[PREENCHER: garantias que devem valer também no banco (restrições, unicidade) e o comportamento esperado sob requisições concorrentes.]

## 8. Critérios de aceitação — BDD

### CA-01 — [PREENCHER: nome]

**Dado** [PREENCHER]\
**Quando** [PREENCHER]\
**Então** [PREENCHER: comportamento observável].

## 9. Requisitos não funcionais

| Aspecto | Requisito | Verificação |
|---|---|---|
| Arquitetura | Respeitar os ADRs e `docs/architecture/` | ArchUnit e revisão |
| Qualidade | [PREENCHER: suítes exigidas] | Harness (`scripts/verify.sh`) |
| Segurança | [PREENCHER: o que nunca pode ser exposto] | Skill `security-review` |
| Observabilidade | [PREENCHER ou Não se aplica] | [PREENCHER] |
| Performance | Metas absolutas só com protocolo de medição reproduzível | Skill `performance-optimization` |

## 10. Fora do escopo

- [PREENCHER: exclusões explícitas.]

## 11. Regras para desenvolvimento com IA

- Versionar e aprovar este PRD antes da implementação.
- Implementar somente requisitos aprovados e especificados no catálogo de features.
- Não permitir que agentes alterem critérios de aceitação ou este PRD unilateralmente.
- Comprovar cada critério de aceitação com evidência verificável produzida pelo harness.
- Exigir revisão humana para aprovar escopo, decisões arquiteturais e conclusão de features.

## 12. Critério de conclusão do produto

Uma implementação é aceita quando satisfaz os critérios de aceitação deste PRD com evidências reproduzíveis e cumpre a `docs/engineering/definition-of-done.md`.

## 13. Glossário

| Termo | Definição |
|---|---|
| [PREENCHER] | [PREENCHER] |

## 14. Aprovação e histórico

**Status:** Rascunho, aguardando aprovação de [PREENCHER].

| Versão | Status | Data | Alterações |
|---|---|---|---|
| 0.1 | Rascunho | [PREENCHER] | Versão inicial |
