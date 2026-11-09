# Workflow de entrega de features

## Uso e fontes de verdade

Este procedimento detalha a [skill feature-delivery](../SKILL.md). Leia apenas as fases necessárias ao trabalho atual; uma solicitação de planejamento ou simulação não autoriza implementação. Os caminhos de comandos são relativos à raiz do repositório; os links Markdown são relativos a este arquivo.

O [AGENTS.md](../../../../AGENTS.md) rege a execução. O [catálogo](../../../../docs/features/README.md) é a fonte de identificação, estados, condições de transição e responsáveis. A [Definition of Done](../../../../docs/engineering/definition-of-done.md) define a conclusão. Não replique esses contratos em regras concorrentes nem interprete este workflow como automação do GitHub.

## Fase 1 — Intake e classificação

Identifique objetivo, problema, resultado esperado e natureza da solicitação: nova funcionalidade, evolução, correção, refatoração ou alteração apenas documental. Diferencie o que o usuário pede agora de possibilidades futuras.

Consulte o [PRD aprovado](../../../../docs/product/prd.md) nas seções relacionadas. Procure uma especificação no catálogo e pelo padrão futuro `docs/features/FEAT-XXXX-*/spec.md`, sem presumir que já exista. Identifique dependências, restrições, riscos e o escopo autorizado, incluindo permissões de escrita e operações Git.

Não escolha regras de produto materialmente relevantes por suposição. Se houver ambiguidade, explique a decisão pendente e solicite esclarecimento; prossiga apenas em atividades independentes já autorizadas. Para trabalho exclusivamente documental, utilize o procedimento de documentação da fase 7 e as verificações documentais da fase 6, sem iniciar o ciclo de implementação funcional.

## Fase 2 — Contrato e especificação

Consulte o [catálogo](../../../../docs/features/README.md) e o [template](../../../../docs/features/TEMPLATE.md), preservando o mecanismo existente:

- Se a demanda estiver no PRD, referencie versão, seções e critérios de aceitação. Não copie o contrato integralmente e confirme a autorização específica de execução.
- Se estiver fora do escopo aprovado, não implemente. Prepare uma proposta de especificação somente quando autorizado, identifique a alteração ou nova versão necessária do PRD e solicite aprovação humana do novo escopo.
- Se já houver especificação, use-a e verifique sua aprovação e eventuais mudanças de escopo. Para ajustes que não exijam especificação própria conforme o catálogo, mantenha a rastreabilidade no relato e nas referências existentes, sem forçar um novo registro.

Para uma demanda real que exija nova especificação, escolha o próximo ID pela sequência e coordenação definidas no catálogo, consultando registros, histórico e propostas em andamento. Não reutilize IDs cancelados nem invente reservas. O destino futuro será `docs/features/FEAT-XXXX-short-description/spec.md`; o padrão não representa um arquivo já existente.

Ao copiar o template:

1. Substitua os placeholders por informações reais; registre pendências ou não aplicabilidade com justificativa, sem inventar IDs, aprovações ou referências externas.
2. Ajuste os links relativos para o diretório adicional: links para `docs/product/` passam de `../product/prd.md` a `../../product/prd.md`; links para a raiz passam de `../../AGENTS.md` a `../../../AGENTS.md`. O link de volta ao catálogo passa de `README.md` a `../README.md`.
3. Verifique a existência de cada destino a partir da localização final. Não deixe links para arquivos inexistentes; identifique caminhos futuros como texto, sem links quebrados.
4. Atualize o catálogo com o ID, status, contrato e link da especificação real, mantendo os dois registros sincronizados.

Crie `design.md` apenas quando a complexidade exigir detalhamento técnico adicional e vincule-o à especificação. Ele não substitui um ADR para decisões arquiteturais relevantes. Não crie features de exemplo para testar a cópia do template.

## Fase 3 — Aprovação

Antes da implementação, confira escopo aprovado, critérios de aceitação verificáveis, autorização específica, dependências resolvidas ou tratadas e decisões arquiteturais necessárias. Uma especificação em **Proposta** não autoriza implementar; a aprovação geral do PRD também não substitui essa autorização.

O pedido atual pode constituir a autorização específica se definir a execução e o escopo e respeitar os contratos vigentes. Use a autorização já concedida, com sua referência real disponível, sem repetir pedidos de confirmação. Registre a decisão na especificação quando houver e aplique as condições de aprovação do catálogo antes de mudar o estado documental.

Se faltar decisão material de produto, autorização ou resolução de conflito contratual, descreva o impedimento, seu impacto e o que precisa ser decidido. Não implemente a parte dependente. Não invente datas, responsáveis, status aprovado ou referências; um agente não aprova o próprio escopo. Aprovação de escopo permite iniciar o trabalho autorizado, enquanto a aprovação de conclusão depende de evidências e revisão humana posterior.

## Fase 4 — Planejamento técnico

Consulte os [princípios do ADR-0001](../../../../docs/architecture/adr/0001-architecture-principles.md), as [convenções de packages](../../../../docs/architecture/package-conventions.md), as [regras de dependência](../../../../docs/architecture/dependency-rules.md) e a [DoD](../../../../docs/engineering/definition-of-done.md) nos pontos afetados.

A stack vigente é Java 27, Spring Boot 4.1.2, Spring MVC, Spring JDBC com SQL explícito, PostgreSQL e Flyway. Organize o negócio por feature, com SOLID, KISS e YAGNI conforme o problema. Não imponha Ports, Adapters ou Use Cases; JPA não é adotado nesta fase e sua introdução exigiria nova decisão arquitetural autorizada.

Defina arquivos e componentes estritamente necessários, responsabilidades, dependências, persistência, transações, riscos e verificações. Não crie packages antecipadamente. Para mudanças não triviais, apresente um plano breve antes de editar. Quando houver decisão relevante, exponha alternativas, trade-offs, riscos e justificativa; um novo ADR depende de autorização humana, sem alterar unilateralmente ADRs aceitos.

## Fase 5 — Implementação

Execute somente após atender à fase 3 e dentro do escopo autorizado. Inspecione os arquivos envolvidos e preserve trabalho preexistente. Implemente a menor solução que satisfaça o contrato e respeite as fronteiras arquiteturais.

Aplique TDD quando apropriado e preserve evidências Red, Green e Refactor quando essa abordagem fizer parte da tarefa. Use os cenários BDD como comportamentos verificáveis, cobrindo sucesso, falha e limites relevantes; BDD não exige Cucumber. Considere concorrência, transações e integridade de dados quando aplicáveis.

Não introduza funcionalidades, dependências ou abstrações fora do escopo nem adapte contratos aprovados para acomodar divergências. Registre mudanças de escopo pelo procedimento do catálogo e obtenha a decisão correspondente antes de implementá-las.

## Fase 6 — Verificação

Inspecione o conteúdo real dos scripts e a configuração atual antes de afirmar capacidades. Prefira o harness versionado, executado em Bash compatível a partir da raiz ou conforme a orientação dos scripts:

| Script existente | Responsabilidade atual |
|---|---|
| [setup.sh](../../../../scripts/setup.sh) | Inspecionar Java, Maven Wrapper e disponibilidade do Docker |
| [build.sh](../../../../scripts/build.sh) | Compilar com Maven Wrapper |
| [test-unit.sh](../../../../scripts/test-unit.sh) | Executar classes elegíveis `*Test.java`; emitir SKIP quando não existirem |
| [test-integration.sh](../../../../scripts/test-integration.sh) | Executar o teste de contexto atual e `*IT`, exigindo Docker funcional |
| [verify.sh](../../../../scripts/verify.sh) | Orquestrar build, unitários elegíveis e integração |
| [guard-branch.sh](../../../../scripts/guard-branch.sh) | Verificar branch antes de operações Git de entrega autorizadas; não integra o verify nem equivale a proteção remota |

Para alterações funcionais, em Java, testes, dependências, build ou configuração de execução, execute quando houver autorização e ambiente disponível:

```bash
bash scripts/verify.sh
```

Relacione os critérios de aceitação aos testes específicos necessários. O teste de contexto atual não comprova uma suíte de negócio ou de contrato; verificações adicionais devem corresponder ao contrato e à configuração real. Não apresente comandos ou ferramentas futuros como operacionais.

Registre cada execução relevante separadamente, com comando ou método, ambiente, revisão da implementação avaliada, resultado observado, data quando disponível, referência da evidência e limitações. Identifique informações indisponíveis sem inventá-las. Os rótulos abaixo pertencem ao relato; não pressupõem que os scripts emitam todos eles:

| Resultado | Significado |
|---|---|
| PASS | Verificação executada e aprovada, com evidência |
| FAIL | Verificação executada e reprovada; registrar falha e investigação |
| SKIP | Verificação explicitamente omitida ou sem testes elegíveis; registrar motivo |
| NOT RUN | Verificação não executada; registrar motivo ou impedimento |

Nunca converta **SKIP** em **PASS**. Código de saída zero do script não prova testes inexistentes nem todos os critérios de aceitação. Se o harness parar em uma falha, registre as etapas posteriores como **NOT RUN**, sem supor sua execução.

Uma execução parcial não substitui resultados anteriores. Preserve cada **FAIL** e sua investigação no histórico, inclusive quando uma execução posterior apresentar **PASS**. Um novo PASS pode demonstrar correção posterior do critério para a revisão e o ambiente avaliados, sem apagar a falha anterior. No resumo, diferencie histórico, resultado da execução atual e obrigações ainda pendentes.

Utilize `SKIP_INTEGRATION=1 bash scripts/verify.sh` somente nas condições permitidas pelo AGENTS.md: omissão explicitamente autorizada ou justificada e comunicada. Declare resultado **parcial**, com a justificativa e os testes não executados. Essa execução registra SKIP para a integração e não transforma uma integração anteriormente reprovada em aprovada; preserve o FAIL anterior e a obrigação não resolvida. Indisponibilidade do Docker não permite omissão silenciosa.

Investigue falhas antes de declarar prontidão. Inclua no relatório final as falhas ainda não investigadas, seus impactos e as ações pendentes; não as oculte. Não remova ou desabilite testes, reduza limites ou altere contratos apenas para obter aprovação. A [DoD, seção Testes e qualidade](../../../../docs/engineering/definition-of-done.md) define quando a obrigação é atendida e seu efeito sobre a conclusão. Verifique a configuração efetiva de JaCoCo, PIT e ArchUnit; no harness atual são mecanismos futuros, sem comprovação de cobertura, mutação ou regras arquiteturais automáticas.

Para alterações exclusivamente documentais, revise links, exemplos, blocos Markdown e o diff completo, inclusive arquivos novos. Execute `git diff --check` e, se existirem alterações preparadas, `git diff --cached --check`. Build e testes Java não são necessários sem justificativa técnica adicional. Informe verificações não executadas; não alegue lint ou checagem automática de links que não existam.

## Fase 7 — Documentação

Consulte a [skill project-documentation](../../project-documentation/SKILL.md) quando disponível e aplique seu procedimento aos documentos impactados. Se estiver ausente no workspace, informe a ausência e siga as regras documentais do AGENTS.md e dos documentos existentes; não invente a skill.

Respeite os requisitos aprovados do PRD e as decisões arquiteturais aceitas como contratos locais, em seus respectivos escopos. Código, testes, scripts e configurações evidenciam o comportamento efetivamente implementado; referências externas apoiam a análise sem substituir os contratos. PRD e ADR não estabelecem precedência automática entre si: conflitos exigem decisão humana, sem alteração unilateral.

Atualize especificação e catálogo quando pertinentes, além das páginas técnicas afetadas. Preserve a distinção entre planejamento e comportamento disponível ao consumidor. Use as categorias Diátaxis da skill de documentação e links para as fontes de verdade, sem duplicar contratos completos. Um plano ou um `design.md` não substitui documentação técnica de referência, tutoriais ou ADRs.

## Fase 8 — Revisão e entrega

Revise o diff completo e os arquivos novos não rastreados. Confirme ausência de alterações inesperadas, escopo cumprido e conformidade com a DoD. Relacione cada critério de aceitação às evidências, identificando falhas, omissões, limitações, riscos e pendências com seus impactos.

Prepare um relatório com objetivo realizado, arquivos envolvidos, decisões e justificativas, comandos e resultados reais, documentação atualizada, verificações não executadas e próximos passos. Uma implementação pode estar pronta para revisão sem a feature estar **Concluída**. Não declare critérios obrigatórios atendidos sem evidência. Para exceções, aplique a [política normativa da DoD](../../../../docs/engineering/definition-of-done.md): registre o critério, a justificativa, o risco, as compensações, o plano de resolução ou reavaliação e a decisão humana verificável nos registros ali definidos. Aprovar uma exceção não aprova testes reprovados nem permite conclusão com critério obrigatório pendente.

Não marque **Concluída** sem revisão humana favorável e referência verificável. Não execute commit ou push sem autorização explícita; publicação não é consequência automática do pedido de implementação. Quando uma operação Git de entrega estiver autorizada, execute antes `bash scripts/guard-branch.sh`, confirme branch, escopo e diff preparado e siga as regras de Conventional Commits do AGENTS.md. Merge, rebase destrutivo e force-push também dependem das autorizações aplicáveis.

## Fase 9 — Transições de estado

Use exclusivamente os sete estados do catálogo: **Proposta**, **Aprovada**, **Em implementação**, **Em validação**, **Concluída**, **Bloqueada** e **Cancelada**. Eles descrevem o estado documental da feature; **PASS**, **FAIL**, **SKIP** e **NOT RUN** descrevem verificações e não são estados adicionais.

Consulte no catálogo quem pode autorizar ou registrar cada transição, suas evidências de entrada e as regras de saída, falha de validação, bloqueio, retomada e cancelamento. Não recrie essas condições aqui. Ao atualizar o estado permitido, sincronize catálogo e especificação, preservando estado anterior, data real, motivo, responsável e referência verificável no histórico.

Um agente pode registrar impedimentos conforme a governança, mas não inventar autorização para aprovar escopo, retomá-lo quando depender de decisão humana, cancelar ou concluir a feature. Se faltar aprovação, preserve o estado compatível e reporte a pendência; não trate passagem de tempo, execução de testes ou publicação no Git como aprovação humana.

## Fase 10 — Experimentação AI-First

Aplique esta fase somente quando a demanda estiver vinculada a um experimento controlado real. Consulte o protocolo existente e autorizado; se faltar definição necessária, registre a pendência antes da execução experimental. Não crie automaticamente protocolos, experimentos ou resultados.

Preserve baseline, revisões de requisitos congelados e critérios de comparação. Registre protocolo, modalidade AI-Assisted ou AI-First, sessão ou execução e revisões Git exatas conforme o catálogo. Respeite branches e worktrees quando realmente definidos pelo protocolo; não presuma isolamento existente.

Registre ferramenta, modelo, versão e ambiente quando disponíveis. Não acesse testes de avaliação ocultos aos agentes, não misture resultados de sessões distintas e não altere critérios para favorecer uma implementação. Diferencie tempo, tokens e custos observados de estimativas e dados indisponíveis; preserve resultados anteriores e reporte falhas e execuções incompletas.
