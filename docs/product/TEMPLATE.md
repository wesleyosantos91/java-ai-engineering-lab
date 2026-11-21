# PRD-NNN — [PREENCHER-NEGÓCIO: nome do produto]

> Modelo de Product Requirements Document. Copie para `docs/product/prd.md` (ou `prd-NNN-*.md`) e substitua cada campo `[PREENCHER-NEGÓCIO: ...]` ou `[PREENCHER-ENGENHARIA: ...]`, apagando também as linhas de orientação (`> Quem preenche ...`) quando a seção estiver pronta. Use `Não se aplica — justificativa` quando pertinente. Um PRD só vira contrato depois de aprovado por revisão humana (seção 14); agentes não alteram PRDs aprovados.

**Projeto:** [PREENCHER-NEGÓCIO: nome do projeto]\
**Versão do documento:** 0.1\
**Status:** Rascunho\
**Responsável pela aprovação:** [PREENCHER-NEGÓCIO: nome e papel de quem aprova]

## Como preencher

O PRD é escrito a quatro mãos. O **time de negócio** descreve o problema, o resultado esperado e as regras em linguagem do dia a dia; a **engenharia** traduz isso em contrato técnico. Nenhuma seção exige conhecimento de programação para quem a preenche.

| Seção | Quem preenche | Obrigatória | Pronta quando |
|---|---|---|---|
| 1. Contexto | Negócio | Sim | Um leitor de fora entende o problema e para quem ele existe |
| 2. Objetivos | Negócio | Sim | Cada objetivo pode ser confirmado ou negado depois da entrega |
| 3. Escopo funcional | Negócio | Sim | Lista o que o sistema faz, sem dizer como |
| 4. Modelo de dados e regras | Ambos | Sim | Negócio definiu as informações e as regras; engenharia, tipos e limites |
| 5. Contrato de interface | Engenharia | Sim | Cada operação tem entrada, saída e resultado de sucesso |
| 6. Representação e erros | Engenharia | Sim | Cada erro previsto tem formato e código estável |
| 7. Integridade e concorrência | Engenharia | Se houver dados compartilhados | Garantias do banco e comportamento simultâneo definidos |
| 8. Critérios de aceitação | Negócio (engenharia revisa) | Sim | Cada regra das seções 3 e 4 tem ao menos um cenário |
| 9. Requisitos não funcionais | Engenharia | Sim | Cada requisito diz como será verificado |
| 10. Fora do escopo | Negócio | Sim | Exclusões explícitas, para evitar expectativas implícitas |
| 13. Glossário | Negócio | Recomendada | Todo termo do domínio usado no PRD está definido |
| 14. Aprovação | Negócio | Sim | Status, responsável e data preenchidos |

As seções 11 e 12 já vêm preenchidas e só mudam por decisão da engenharia. Para listar o que falta, por responsável: `bash scripts/product/check-prd.sh`. O PRD não pode ter Status **Aprovado** enquanto houver campos `[PREENCHER-...]`.

## 1. Contexto

> **Quem preenche:** Negócio · **Obrigatória** · **Dica:** qual problema existe hoje, quem sofre com ele e por que resolvê-lo agora. Separe fatos (dados, reclamações) de hipóteses.
>
> *Exemplo:* "Pedidos de reposição são feitos por planilha; em média 1 em cada 10 chega com quantidade errada (relatório de março). A equipe de compras quer registrar pedidos num sistema com validação."

[PREENCHER-NEGÓCIO: problema, público afetado, motivação e restrições conhecidas.]

## 2. Objetivos

> **Quem preenche:** Negócio · **Obrigatória** · **Dica:** resultados observáveis, não funcionalidades. Prefira "reduzir erros de quantidade" a "ter uma tela de pedidos".

- [PREENCHER-NEGÓCIO: resultado esperado e verificável.]

## 3. Escopo funcional

> **Quem preenche:** Negócio · **Obrigatória** · **Dica:** um verbo por item ("cadastrar", "consultar", "cancelar"). Diga o que o sistema faz, não como.

O sistema deverá permitir:

- [PREENCHER-NEGÓCIO: capacidade funcional.]

## 4. Modelo de dados e regras de domínio

> **Quem preenche:** Ambos · **Obrigatória** · **Negócio:** quais informações existem, quais são obrigatórias e quais regras valem (por exemplo "o código é único", "a quantidade é maior que zero"). **Engenharia:** tipo lógico, formato, limites e normalização, sem ambiguidade: dois leitores devem derivar os mesmos testes.

| Campo | Tipo lógico | Regra |
|---|---|---|
| [PREENCHER-NEGÓCIO: nome da informação] | [PREENCHER-ENGENHARIA: tipo lógico] | [PREENCHER-NEGÓCIO: obrigatoriedade e regra de negócio] [PREENCHER-ENGENHARIA: formato, limites, normalização, unicidade] |

[PREENCHER-ENGENHARIA: regras de normalização, validação e invariantes por campo.]

## 5. Contrato de interface

> **Quem preenche:** Engenharia · **Obrigatória** · **Dica:** derive as operações do escopo (seção 3) e dos critérios (seção 8).

[PREENCHER-ENGENHARIA: rotas ou operações, métodos, status de sucesso, parâmetros, paginação e ordenação. Para APIs HTTP, inclua uma tabela de operações e o comportamento de cada uma.]

## 6. Representação e erros

> **Quem preenche:** Engenharia · **Obrigatória** · **Negócio contribui** com a mensagem esperada pelo usuário em cada erro de regra.

[PREENCHER-ENGENHARIA: campos aceitos e retornados, rejeição de campos desconhecidos, tipos JSON exigidos, formato de erro (por exemplo `ProblemDetail`, RFC 9457) e códigos de erro estáveis.]

## 7. Integridade e concorrência

> **Quem preenche:** Engenharia · **Obrigatória se houver dados compartilhados** · **Dica:** o que acontece se duas pessoas fizerem a mesma operação ao mesmo tempo.

[PREENCHER-ENGENHARIA: garantias que devem valer também no banco (restrições, unicidade) e o comportamento esperado sob requisições concorrentes.]

## 8. Critérios de aceitação — BDD

> **Quem preenche:** Negócio, com revisão da engenharia · **Obrigatória** · **Dica:** um cenário por regra, inclusive os casos de recusa. Escreva o que uma pessoa veria, sem termos técnicos; a engenharia transforma cada cenário em teste automatizado.
>
> *Exemplo:* **Dado** um pedido com quantidade zero **Quando** o comprador tenta registrá-lo **Então** o pedido é recusado com a mensagem "a quantidade deve ser maior que zero".

### CA-01 — [PREENCHER-NEGÓCIO: nome do cenário]

**Dado** [PREENCHER-NEGÓCIO: situação inicial]\
**Quando** [PREENCHER-NEGÓCIO: ação]\
**Então** [PREENCHER-NEGÓCIO: resultado observável].

## 9. Requisitos não funcionais

> **Quem preenche:** Engenharia · **Obrigatória** · **Negócio informa** restrições conhecidas (dados sensíveis, volume esperado, horário de uso).

| Aspecto | Requisito | Verificação |
|---|---|---|
| Arquitetura | Respeitar os ADRs e `docs/architecture/` | ArchUnit e revisão |
| Qualidade | [PREENCHER-ENGENHARIA: suítes exigidas] | Harness (`scripts/verify.sh`) |
| Segurança | [PREENCHER-ENGENHARIA: o que nunca pode ser exposto] | Skill `security-review` |
| Observabilidade | [PREENCHER-ENGENHARIA: requisito ou Não se aplica] | [PREENCHER-ENGENHARIA: como verificar] |
| Performance | Metas absolutas só com protocolo de medição reproduzível | Skill `performance-optimization` |

## 10. Fora do escopo

> **Quem preenche:** Negócio · **Obrigatória** · **Dica:** o que alguém poderia esperar e não será entregue nesta versão.

- [PREENCHER-NEGÓCIO: exclusões explícitas.]

## 11. Regras para desenvolvimento com IA

- Versionar e aprovar este PRD antes da implementação.
- Implementar somente requisitos aprovados e especificados no catálogo de features.
- Não permitir que agentes alterem critérios de aceitação ou este PRD unilateralmente.
- Comprovar cada critério de aceitação com evidência verificável produzida pelo harness.
- Exigir revisão humana para aprovar escopo, decisões arquiteturais e conclusão de features.

## 12. Critério de conclusão do produto

Uma implementação é aceita quando satisfaz os critérios de aceitação deste PRD com evidências reproduzíveis e cumpre a `docs/engineering/definition-of-done.md`.

## 13. Glossário

> **Quem preenche:** Negócio · **Recomendada** · **Dica:** termos que a equipe usa e um recém-chegado não conheceria.

| Termo | Definição |
|---|---|
| [PREENCHER-NEGÓCIO: termo] | [PREENCHER-NEGÓCIO: definição] |

## 14. Aprovação e histórico

> **Quem preenche:** Negócio · **Obrigatória** · **Dica:** ao aprovar, troque o Status do cabeçalho e desta seção para `Aprovado` e registre a data. A verificação rejeita aprovação com campos pendentes.

**Status:** Rascunho, aguardando aprovação de [PREENCHER-NEGÓCIO: responsável].

| Versão | Status | Data | Alterações |
|---|---|---|---|
| 0.1 | Rascunho | [PREENCHER-NEGÓCIO: data] | Versão inicial |
