---
name: feature-delivery
description: >-
  Orienta o ciclo de entrega funcional do Java AI Engineering Lab, do contrato e da
  autorização às evidências e à revisão humana. Use para criar uma nova feature,
  evoluir uma funcionalidade existente, implementar um requisito do PRD, corrigir
  comportamento de uma feature, planejar e executar uma entrega funcional ou
  validar seus critérios de aceitação. Para tarefas exclusivamente documentais,
  utilize project-documentation.
---

# Feature Delivery

## Objetivo e limites

Coordenar entregas reproduzíveis e auditáveis conforme o [AGENTS.md](../../../AGENTS.md), que permanece a instrução global do repositório. A skill orienta o processo; sua leitura não autoriza implementar, modificar contratos ou executar operações Git de entrega.

O [catálogo](../../../docs/features/README.md) mantém identificação, estados, aprovações e governança. Use a especificação existente e a autorização vigente da solicitação; não exija nova confirmação para ações já autorizadas. Se houver ambiguidade material ou conflito com o contrato, esclareça a decisão pendente antes da ação dependente.

## Fluxo principal

1. Classifique a demanda e localize contrato, especificação, restrições e dependências. Confirme o escopo autorizado; aprovação do PRD geral não autoriza toda implementação.
2. Planeje e execute somente o trabalho autorizado, conforme os documentos arquiteturais e os critérios BDD pertinentes. Não crie especificações, packages ou decisões especulativas.
3. Selecione verificações a partir do harness real e registre resultados executados, falhos, omitidos ou não executados. Acione o procedimento da [skill project-documentation](../project-documentation/SKILL.md) para documentação impactada; se ausente, informe e use as regras locais.
4. Relacione evidências aos critérios de aceitação e à DoD, revise o diff e prepare a revisão humana. Atualize especificação e catálogo somente nas condições permitidas; Concluída exige revisão humana favorável verificável. Commit e push exigem autorização explícita.

## Referência sob demanda

Consulte o [workflow operacional](references/workflow.md) apenas nas fases pertinentes à solicitação:

- Fases 1–3: intake, contrato, especificação e aprovação.
- Fases 4–6: planejamento, implementação e verificação.
- Fases 7–9: documentação, revisão e transições de estado.
- Fase 10: experimentos controlados, somente quando vinculados ao trabalho.

Carregue PRD, ADRs, documentos de engenharia e referências especializadas conforme a necessidade de cada fase, sem ler todo o repositório automaticamente. A saída esperada é um relato do escopo realizado, arquivos envolvidos, critérios atendidos, comandos e resultados reais, limitações e decisões humanas pendentes.

## Compatibilidade

A localização canônica é `.agents/skills/feature-delivery/SKILL.md`. A descoberta desse caminho depende do cliente; sua existência ou referência no AGENTS.md não garante ativação automática em Codex, Claude, GitHub Copilot ou Devin. Se necessário, leia o arquivo explicitamente. Não duplique a skill em diretórios de provedores sem necessidade comprovada e decisão autorizada.

O formato segue a [especificação Agent Skills](https://agentskills.io/specification). Nenhum comando específico de provedor é necessário para executar este fluxo.
