# Catálogo de features

## Propósito e público

Este diretório reúne especificações de trabalho versionadas no Git para responsáveis de produto, engenharia, revisores e agentes de IA. O catálogo permite registrar demandas, acompanhar seu ciclo de vida e relacionar escopo, dependências, decisões e evidências de entrega.

As especificações detalham o trabalho autorizado e não substituem os contratos do projeto:

| Fonte | Relação com as features |
|---|---|
| [PRD](../product/prd.md) | Define requisitos aprovados e critérios de aceitação; referencie versão e seções pertinentes |
| [Princípios de arquitetura — ADR-0001](../architecture/adr/0001-architecture-principles.md) | Registra decisões arquiteturais aceitas |
| [Convenções de packages](../architecture/package-conventions.md) e [regras de dependência](../architecture/dependency-rules.md) | Orientam organização e fronteiras técnicas |
| [Definition of Done](../engineering/definition-of-done.md) | Define critérios de conclusão e política de exceções |
| [AGENTS.md](../../AGENTS.md) | Orienta descoberta de contexto, autonomia, implementação e uso do harness local |
| [Skill project-documentation](../../.agents/skills/project-documentation/SKILL.md) | Orienta estrutura editorial, validação e atualização da documentação |

Consulte outras skills de engenharia somente quando existirem e forem pertinentes à tarefa; este catálogo não pressupõe sua instalação. Código, testes, scripts e configurações comprovam o comportamento implementado, sem autorizar alterações unilaterais no PRD ou em ADRs aceitos. Registre e encaminhe divergências ao responsável técnico.

No modelo Diátaxis, esta página é uma referência de governança; o template e as especificações são artefatos de planejamento e acompanhamento. A documentação de uso continua separada conforme sua finalidade: tutorial para aprendizagem, how-to para executar tarefas, referência para contratos e explicação para mecanismos e trade-offs. Especificações e `design.md` não substituem essas páginas nem ADRs.

## Organização

Arquivos presentes neste catálogo:

```text
docs/features/
├── README.md
└── TEMPLATE.md
```

Estrutura futura, apenas ilustrativa; o diretório de exemplo abaixo não representa uma feature cadastrada:

```text
docs/features/
└── FEAT-0001-example-feature/
    ├── spec.md
    └── design.md
```

| Arquivo | Responsabilidade |
|---|---|
| `README.md` | Manter convenções, governança e índice das features registradas |
| [TEMPLATE.md](TEMPLATE.md) | Fornecer o modelo reutilizável para `spec.md` |
| `spec.md` | Registrar problema, escopo, requisitos, BDD, dependências, validações e aprovações de uma feature real |
| `design.md` | Opcional: detalhar desenho técnico, alternativas, falhas e trade-offs quando a complexidade justificar |

Crie `design.md` apenas quando houver conteúdo necessário e faça o vínculo a partir de `spec.md`. Uma decisão arquitetural relevante deve ser registrada em ADR autorizado e referenciada nos dois documentos, quando aplicável.

Ao copiar o template para um diretório de feature, ajuste os links relativos: o template está diretamente em `docs/features/`, enquanto `spec.md` ficará um nível abaixo. Não crie diretórios ou documentos vazios antecipadamente.

## Identificação

- Use IDs sequenciais: `FEAT-0001`, `FEAT-0002`, `FEAT-0003` e assim por diante.
- Use o formato `FEAT-XXXX-short-description`, com número de quatro dígitos e descrição curta em inglês, em letras minúsculas separadas por hífen.
- Antes de reservar o próximo ID, consulte este catálogo, os diretórios existentes, o histórico Git e propostas em andamento com os responsáveis. Use o maior número já atribuído mais um; o primeiro será `FEAT-0001`.
- Coordene registros simultâneos para evitar IDs duplicados; não há gerador ou controle automático de sequência.
- Mantenha o ID e o diretório estáveis. Não reutilize IDs, inclusive após cancelamento; preserve a especificação e sua linha no catálogo como histórico.
- Mantenha o mesmo ID em catálogo, especificação, evidências e referências cruzadas.

## Ciclo de vida e aprovações

O responsável pela feature mantém `spec.md` e esta tabela de catálogo consistentes. Toda transição deve registrar estado anterior e novo, data, responsável, motivo e referência verificável na especificação. Uma conversa autorizadora pode ser referenciada por identificador e data; não copie informações sensíveis.

| Status | Significado | Quem pode autorizar ou registrar | Evidências necessárias para entrada |
|---|---|---|---|
| Proposta | Demanda registrada, ainda não aprovada | Responsável pela demanda ou agente autorizado a registrá-la | Problema, objetivo, escopo proposto, contrato relacionado e pendências de definição |
| Aprovada | Requisitos e escopo autorizados | Responsável humano pelo produto ou escopo; responsável técnico quando houver impactos técnicos que exijam decisão | Decisão verificável, responsável, data, versão do escopo e critérios de aceitação aprovados |
| Em implementação | Desenvolvimento em andamento | Responsável pela execução ou agente, dentro da aprovação registrada | Aprovação vigente, branch e plano compatível com o escopo |
| Em validação | Implementação submetida aos critérios de aceitação e verificações | Responsável pela execução ou agente | Referência da implementação ou diff disponível, relação com critérios BDD, resultados já obtidos e verificações ainda pendentes |
| Concluída | Requisitos e critérios obrigatórios atendidos, com revisão humana | Revisor humano designado pelo responsável técnico | Evidências de aceitação e DoD, documentação atualizada, pendências tratadas e referência da revisão humana favorável |
| Cancelada | Demanda encerrada sem implementação | Responsável humano pelo escopo | Motivo, decisão de cancelamento e impactos nas dependências; preservar o ID e o histórico |
| Bloqueada | Existe impedimento documentado | Responsável pela execução ou agente pode registrar o impedimento; responsável técnico autoriza a retomada | Impedimento, impacto, responsável pelo desbloqueio, condição de resolução e estado anterior |

O fluxo ordinário é **Proposta → Aprovada → Em implementação → Em validação → Concluída**. Falhas de validação podem devolver a feature a **Em implementação** dentro do escopo aprovado, com motivo e evidências. Pendências de definição impedem a aprovação; registrar uma proposta não autoriza sua implementação.

Um impedimento pode levar uma feature ativa a **Bloqueada**. A retomada exige evidência da resolução e retorna ao estado anterior ainda válido; mudanças de escopo exigem nova aprovação antes de implementar. Uma proposta ou demanda aprovada sem implementação pode ser **Cancelada**. Se já houver trabalho parcial, submeta seu destino ao responsável humano e documente-o antes de decidir o encerramento; não o oculte como demanda sem implementação.

**Concluída** e **Cancelada** encerram o ciclo registrado. Novas demandas após o encerramento recebem outro ID, com referência à anterior. Correções documentais devem preservar o histórico das decisões.

Os estados são mantidos manualmente nos arquivos. Não criam issues, labels, projetos, checks ou automações no GitHub. Um agente pode reunir evidências e propor transições, mas não inventar aprovações nem substituir a revisão humana.

## Catálogo de features

Não há features cadastradas neste catálogo.

| ID | Nome | Status | Contrato de referência | Link da especificação |
|---|---|---|---|---|

Ao registrar uma demanda real, inclua uma linha e um link relativo para seu `spec.md`, mantendo o status sincronizado com a especificação. Não preencha a tabela com exemplos ou capacidades futuras sem demanda registrada.

## Governança do escopo e dos contratos

### Criar uma especificação

Crie uma especificação quando uma nova demanda precisar de escopo, critérios de aceitação e acompanhamento próprios, antes de iniciar sua implementação. Primeiro verifique se ela já está coberta pelo PRD ou por outra feature; não abra registros duplicados. Ajustes pequenos podem seguir o fluxo existente quando não exigirem uma especificação própria, respeitando o escopo autorizado.

Copie o [template](TEMPLATE.md) apenas para uma demanda real, substitua os placeholders e registre-a como **Proposta** até existir aprovação verificável. Se o contrato não estiver definido, registre essa pendência; a especificação não cria autorização por si só.

### Atualizar PRD e registrar ADR

Se a demanda apenas executar um contrato existente, referencie suas seções e critérios, sem copiar o PRD integralmente. Alterações de comportamento, regras ou critérios aprovados exigem autorização do responsável humano e nova versão do PRD conforme sua política de aprovação. Não ajuste o contrato para justificar uma implementação divergente.

Crie um ADR quando uma decisão arquitetural relevante introduzir ou alterar escolhas e fronteiras aprovadas, após autorização e revisão técnica. Detalhes locais que respeitem as decisões existentes não exigem um ADR por feature. Preserve ADRs aceitos e registre decisões posteriores em novos ADRs conforme a política vigente.

### Registrar mudanças de escopo

Na especificação, mantenha o histórico com data, escopo anterior, alteração proposta, motivo, impactos em requisitos, BDD, dependências e documentação, além da decisão e sua referência. Preserve a versão aprovada anterior pelo Git. Aguarde aprovação do novo escopo antes de implementá-lo; se isso impedir a continuidade, registre o bloqueio. Atualize os documentos afetados somente dentro da autorização recebida.

### Documentar dependências

Relacione cada dependência por ID e link para a especificação existente. Descreva o contrato necessário, a condição de liberação e o impacto de atraso ou cancelamento. Diferencie dependência obrigatória de simples relação. Dependências ainda não cadastradas devem ser identificadas como pendências, sem links para arquivos inexistentes. Registre os impactos também na feature afetada e encaminhe ciclos ou conflitos ao responsável técnico.

### Preservar experimentos AI-Assisted e AI-First

Antes de executar um experimento, identifique na especificação o protocolo autorizado, a modalidade, a sessão ou execução, o commit de baseline e as revisões exatas de PRD, ADRs e especificação. Use referências Git imutáveis para recuperar os contratos congelados, sem sobrescrever resultados anteriores.

Mudanças posteriores exigem decisão registrada e avaliação no protocolo experimental; não misture medições de contratos ou sessões diferentes. Registre ferramentas e modelos quando aplicável, comandos, ambiente e resultados observados. Separe medições de estimativas e mantenha testes de avaliação independente fora do contexto dos agentes conforme o PRD. Não invente tempo, tokens, custo ou resultados.

## Validação e documentação da entrega

Use o harness local indicado no [AGENTS.md](../../AGENTS.md), conforme a natureza da mudança. Para alterações funcionais, registre resultados e omissões dos testes pertinentes; o harness atual não comprova sozinho todos os critérios de negócio ou de contrato.

Para alterações exclusivamente documentais, revise o diff completo, incluindo arquivos novos, confira links e execute `git diff --check`. Execute `git diff --cached --check` quando houver alterações preparadas. Não alegue lint ou validação automática de links inexistentes. Ferramentas futuras só podem ser exigidas como operacionais após sua configuração e validação efetiva.

Atualize as páginas técnicas impactadas conforme Diátaxis, mantenha evidências na especificação e apresente o trabalho para revisão humana. O preenchimento de checklists ou a mudança de status não constitui aprovação automática.
