# Especificação de feature — [PREENCHER: nome]

> Modelo para copiar para um futuro `docs/features/FEAT-XXXX-short-description/spec.md`. Este arquivo não registra uma feature, implementação ou aprovação. Substitua os campos `[PREENCHER: ...]`; use `Não se aplica — justificativa` quando pertinente e `Pendente — motivo` quando faltar informação. Nenhum checkbox representa validação já executada.
>
> Consulte a [governança do catálogo](README.md). Os links deste template funcionam em `docs/features/`; ao copiá-lo para `spec.md`, ajuste os links relativos para o nível adicional de diretório e valide-os. Caminhos futuros devem permanecer explicitamente identificados como tal, sem links quebrados.

## 1. Identificação

| Campo | Valor |
|---|---|
| ID | [PREENCHER: FEAT-XXXX, conforme sequência do catálogo] |
| Nome | [PREENCHER: nome da demanda] |
| Status | Proposta — valor inicial ao registrar; atualizar conforme o ciclo de vida |
| Responsável | [PREENCHER: pessoa responsável pelo acompanhamento] |
| Contrato de referência | [PREENCHER: link, versão e seções do PRD; ADRs pertinentes; ou pendência de definição] |
| Branch | [PREENCHER: branch de trabalho autorizada conforme AGENTS.md] |
| Issue ou PR relacionado | [PREENCHER: referência existente, ou ainda não criado] |
| Dependências | [PREENCHER: IDs e links existentes, condição de liberação e impacto; ou nenhuma identificada] |
| Referência da aprovação | [PREENCHER: referência verificável, ou pendente; ver seção 13] |

Não interprete a aprovação de um contrato geral como autorização automática para executar esta feature. Consulte o [PRD](../product/prd.md), os [princípios arquiteturais](../architecture/adr/0001-architecture-principles.md) e o [AGENTS.md](../../AGENTS.md) no escopo pertinente.

## 2. Contexto e problema

[PREENCHER: problema observado, público afetado, motivação de negócio, contexto e evidências disponíveis. Diferencie fatos comprovados de hipóteses e capacidades futuras.]

## 3. Objetivo

[PREENCHER: resultado esperado e como verificá-lo. Inclua indicadores e método de avaliação quando aplicáveis, sem criar metas arbitrárias.]

## 4. Escopo

### Incluído

- [PREENCHER: comportamento ou resultado autorizado.]

### Fora do escopo

- [PREENCHER: exclusões explícitas para delimitar a entrega.]

### Histórico de escopo e estados

Registre mudanças e transições sem apagar decisões anteriores; referencie a revisão Git do escopo aprovado. Para mudanças de escopo, inclua os impactos e aguarde nova aprovação antes de implementá-las.

| Data | Estado ou escopo anterior → novo | Motivo e impactos | Responsável | Decisão e referência verificável |
|---|---|---|---|---|
| [PREENCHER] | [PREENCHER] | [PREENCHER: requisitos, BDD, dependências e documentos afetados] | [PREENCHER] | [PREENCHER: decisão real ou pendente] |

### Impedimentos

[PREENCHER: impedimento, impacto, estado anterior, responsável pelo desbloqueio, condição de resolução e evidência para retomada; ou nenhum identificado.]

## 5. Requisitos funcionais

Referencie as seções e os critérios existentes do PRD; não replique contratos completos. Descreva os comportamentos específicos da demanda e identifique propostas ainda não aprovadas.

| Referência do requisito | Comportamento observável e regras | Entradas e saídas | Falhas esperadas | Fonte contratual |
|---|---|---|---|---|
| [PREENCHER: identificador local ou referência existente] | [PREENCHER] | [PREENCHER] | [PREENCHER] | [PREENCHER: link, versão e seção] |

## 6. Critérios de aceitação BDD

Repita o formato para cenários de sucesso, falha e situações-limite, vinculando-os aos requisitos e critérios do PRD. BDD não exige Cucumber.

### Cenário — [PREENCHER: identificador e nome]

**Requisito relacionado:** [PREENCHER: referência verificável]

**Dado** [PREENCHER: contexto inicial]

**Quando** [PREENCHER: ação executada]

**Então** [PREENCHER: comportamento observável esperado].

**Como comprovar:** [PREENCHER: teste ou verificação correspondente; após a execução, referenciar a evidência na seção 12.]

## 7. Requisitos não funcionais

Preencha apenas critérios aplicáveis, com fonte, método de verificação e limites aprovados. Marque os demais como não aplicáveis com justificativa; registre metas indefinidas como pendências, sem inventar números.

| Aspecto | Requisito aplicável e fonte | Método de verificação ou justificativa |
|---|---|---|
| Segurança | [PREENCHER] | [PREENCHER] |
| Performance | [PREENCHER: meta aprovada ou pendência; protocolo de medição quando necessário] | [PREENCHER] |
| Observabilidade | [PREENCHER] | [PREENCHER] |
| Disponibilidade e confiabilidade | [PREENCHER] | [PREENCHER] |
| Concorrência | [PREENCHER] | [PREENCHER] |
| Integridade de dados | [PREENCHER] | [PREENCHER] |

## 8. Considerações técnicas

Registre apenas o necessário para avaliar viabilidade, impactos e riscos. Não imponha implementação detalhada quando o contrato funcional bastar. Respeite as [convenções de packages](../architecture/package-conventions.md) e as [regras de dependência](../architecture/dependency-rules.md); não crie packages antecipadamente.

| Aspecto | Avaliação |
|---|---|
| Impacto arquitetural | [PREENCHER: componentes e fronteiras afetados; ADRs relacionados] |
| Packages e features envolvidos | [PREENCHER: existentes; distinguir qualquer previsão futura] |
| Persistência e transações | [PREENCHER: dados, SQL, migrações, integridade e limites transacionais; ou não aplicável] |
| Integrações | [PREENCHER: contratos e falhas esperadas; ou não aplicável] |
| Dependências técnicas e entre features | [PREENCHER: links existentes, condições de liberação e impactos] |
| Riscos e trade-offs | [PREENCHER: alternativas, impactos e mitigação] |
| Necessidade de ADR | [PREENCHER: sim/não com justificativa; autorização e referência quando existir] |
| Necessidade de design.md | [PREENCHER: sim/não com justificativa; incluir link somente após criar o arquivo opcional] |

## 9. Estratégia de testes

Planeje as verificações e relacione cada critério BDD a um teste ou evidência. Planejamento não comprova execução; resultados ficam na seção 12.

| Tipo | Cenários e critérios cobertos | Comando ou método previsto | Aplicabilidade e limitações |
|---|---|---|---|
| Unitários | [PREENCHER] | [PREENCHER] | [PREENCHER] |
| Integração | [PREENCHER: persistência, transações e integrações pertinentes] | [PREENCHER] | [PREENCHER: ambiente e Docker quando necessário] |
| Contrato | [PREENCHER: entradas, saídas e erros observáveis] | [PREENCHER] | [PREENCHER] |
| Falhas e situações-limite | [PREENCHER] | [PREENCHER] | [PREENCHER] |
| Concorrência | [PREENCHER] | [PREENCHER] | [PREENCHER: quando aplicável] |
| Quality Gates configurados | [PREENCHER: mecanismos efetivamente operacionais] | [PREENCHER] | [PREENCHER: não confundir com metas futuras] |

O [harness descrito no AGENTS.md](../../AGENTS.md) é a referência operacional. Para código, build ou configuração de execução, utilize prioritariamente `bash scripts/verify.sh`, que reúne compilação, unitários elegíveis e integração com Docker. O teste de contexto existente não equivale a uma suíte de negócio ou de contrato. `SKIP` por ausência de unitários não significa testes aprovados.

JaCoCo, PIT e ArchUnit são mecanismos futuros no estado atual do harness; não registre cobertura, mutation score ou validação arquitetural automática sem configuração e execução verificáveis. Reavalie esse estado ao usar o template. Não crie comandos fictícios para verificações ainda não implementadas.

Para mudanças exclusivamente documentais, revise links, exemplos e diff e execute `git diff --check`; use `git diff --cached --check` se houver alterações preparadas. Omissões de verificações aplicáveis devem ser justificadas; integração omitida implica resultado parcial conforme AGENTS.md.

## 10. Documentação impactada

Identifique quais páginas técnicas precisam acompanhar a entrega. Especificações não substituem documentação de uso, referência ou decisões arquiteturais.

| Documento existente ou destino futuro explícito | Categoria ou finalidade | Alteração necessária | Situação e evidência |
|---|---|---|---|
| [PREENCHER: link existente, ou caminho futuro identificado sem link] | [PREENCHER: tutorial, how-to, referência, explicação, especificação ou ADR] | [PREENCHER] | [PREENCHER: pendente ou evidência real] |

Atualize também o catálogo e consulte a [skill project-documentation](../../.agents/skills/project-documentation/SKILL.md), quando disponível. Alterações do PRD e decisões arquiteturais dependem das autorizações correspondentes.

## 11. Critérios de conclusão

Use a [Definition of Done](../engineering/definition-of-done.md) como fonte normativa; este checklist resume os pontos a verificar, sem substituí-la. Associe evidências da seção 12 a cada item. Não marque uma verificação não realizada como aprovada; registre não aplicabilidade ou exceções conforme a política da DoD, com decisão do responsável técnico quando exigida.

- [ ] Escopo e critérios de aceitação aprovados foram atendidos, incluindo sucesso, falhas e limites.
- [ ] Comportamento implementado corresponde ao contrato e não inclui funcionalidades fora do escopo.
- [ ] Arquitetura, fronteiras, dependências e organização Feature-Based foram respeitadas.
- [ ] Testes pertinentes foram implementados e executados, com resultados, falhas e omissões registrados.
- [ ] Quality Gates efetivamente configurados foram verificados; mecanismos futuros permanecem identificados como pendentes.
- [ ] Persistência, migrações e transações foram verificadas quando aplicáveis.
- [ ] Segurança, observabilidade e performance foram avaliadas conforme o impacto e os critérios aprovados.
- [ ] Documentação técnica, especificação e catálogo foram atualizados e seus links revisados.
- [ ] Participação dos agentes, decisões e evidências estão rastreáveis, sem resultados inventados.
- [ ] Referências de entrega existentes foram registradas; commits e PRs ocorreram somente quando autorizados.
- [ ] Pendências e exceções foram tratadas conforme a DoD, sem ocultar critérios obrigatórios não atendidos.
- [ ] Revisão humana favorável foi registrada com referência verificável antes da transição para Concluída.

## 12. Evidências

### Execuções e resultados

| Data e ambiente | Critério BDD ou item da DoD | Comando realmente executado ou método utilizado | Resultado observado e referência da evidência |
|---|---|---|---|
| [PREENCHER] | [PREENCHER] | [PREENCHER: somente após executar] | [PREENCHER: saída, status e limitações reais] |

### Verificações não executadas

| Teste ou verificação | Justificativa da omissão | Impacto na aceitação | Decisão ou ação pendente |
|---|---|---|---|
| [PREENCHER] | [PREENCHER] | [PREENCHER: parcial, impedido ou não aplicável] | [PREENCHER] |

### Referências de entrega

- Commits: [PREENCHER: hashes existentes ou ainda não criados; nunca inventar referências].
- Pull requests: [PREENCHER: links existentes ou ainda não criados].
- Pendências e riscos: [PREENCHER: descrição, impacto, responsável e próximo passo; ou nenhum identificado].

### Rastreabilidade experimental e participação de IA

Preencha quando houver experimento ou participação de agentes. Se não houver, registre essa condição sem inventar protocolo ou medições.

| Campo | Registro |
|---|---|
| Modalidade | [PREENCHER: AI-Assisted, AI-First ou não aplicável] |
| Protocolo e execução | [PREENCHER: referência existente, identificação da execução e sessão; ou pendente] |
| Baseline e contratos congelados | [PREENCHER: commit e revisões exatas de PRD, ADRs e especificação] |
| Ferramentas, modelos e ambiente | [PREENCHER: versões e dados observados quando disponíveis] |
| Intervenções humanas | [PREENCHER: decisões, motivo e referências] |
| Medições e limitações | [PREENCHER: resultados separados por execução; distinguir medições de estimativas e dados indisponíveis] |

## 13. Aprovação

A aprovação de escopo e a revisão de conclusão são decisões distintas. Preencha somente após decisões reais; mantenha as linhas anteriores ao registrar revisões. Uma referência pode ser issue, PR, documento versionado ou identificador de solicitação com data, desde que permita verificar a autorização.

| Etapa | Decisão | Responsável humano | Data | Escopo ou revisão avaliada | Referência verificável |
|---|---|---|---|---|---|
| Aprovação do escopo | [PREENCHER: pendente até decisão real] | [PREENCHER] | [PREENCHER] | [PREENCHER] | [PREENCHER] |
| Alteração do escopo, quando houver | [PREENCHER: pendente ou não aplicável] | [PREENCHER] | [PREENCHER] | [PREENCHER] | [PREENCHER] |
| Revisão de conclusão | [PREENCHER: pendente até revisão humana] | [PREENCHER] | [PREENCHER] | [PREENCHER] | [PREENCHER] |

Somente atualize o status e o catálogo conforme a decisão registrada e as evidências disponíveis. Não declare Concluída uma feature com critérios obrigatórios pendentes.
