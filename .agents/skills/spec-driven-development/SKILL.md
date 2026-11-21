---
name: spec-driven-development
description: >-
  Redige ou revisa a especificação de uma feature (spec.md) como contrato verificável
  antes da implementação, usando o template do projeto e critérios BDD. Use quando uma
  demanda precisar ser registrada como Proposta ou ajustada antes da aprovação. Não use
  para alterar especificação aprovada sem autorização nem para implementar código.
---

# Spec-Driven Development

## Objetivo e limites

A especificação é o contrato da feature: código e testes derivam dela, não o contrário. Use o [template](../../../docs/features/TEMPLATE.md) e as regras de identificação e estados do [catálogo](../../../docs/features/README.md). O agente registra no máximo o estado **Proposta**; a aprovação é decisão humana verificável.

## Procedimento

1. Parta do resultado da [requirements-discovery](../requirements-discovery/SKILL.md) ou de requisito já presente no PRD.
2. Confirme no catálogo o próximo identificador e se já existe especificação relacionada.
3. Preencha o template sem remover seções; marque o que estiver indefinido como pendência, nunca como decisão.
4. Escreva requisitos funcionais atômicos e rastreáveis ao PRD.
5. Escreva cenários BDD (`Dado`/`Quando`/`Então`) observáveis, cobrindo sucesso, erro e limites. Cada cenário deve ser comprovável por um teste automatizado identificável.
6. Declare requisitos não funcionais apenas quando houver métrica ou critério verificável.
7. Liste a documentação impactada e a estratégia de testes, sem prometer ferramentas não configuradas.
8. Atualize a linha do catálogo de forma consistente com a especificação.

## Critérios de qualidade

- Sem ambiguidade: dois leitores derivariam os mesmos testes.
- Sem detalhes de implementação além das restrições arquiteturais necessárias.
- Sem contradição com PRD e ADRs; divergências ficam registradas como pendências.

## Validação

Revise o diff e execute `git diff --check`. Siga a [skill project-documentation](../project-documentation/SKILL.md) para padrões editoriais.
