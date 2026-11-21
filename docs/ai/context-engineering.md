# Context engineering e harness para agentes

Explicação de como o repositório entrega contexto e limites aos agentes de IA (Codex, Claude Code e Devin) e de como essa configuração é verificada. A decisão está registrada no [ADR-0002](../architecture/adr/0002-multi-provider-agent-context.md), ainda com status Proposta.

## Problema

Um agente produz resultados melhores quando recebe o contexto certo no momento certo. Contexto demais desperdiça a janela e dilui regras importantes; contexto de menos leva a decisões inventadas. Além disso, cada provider descobre instruções de um jeito, e um repositório de referência precisa que todos recebam as mesmas regras.

## Camadas de contexto

| Camada | Quando é carregada | Conteúdo | Arquivos |
|---|---|---|---|
| 1. Sempre carregada | Início de toda sessão | Regras invioláveis, mapa de contexto e catálogo de skills | [`AGENTS.md`](../../AGENTS.md) (≤ 12 KB, verificado) |
| 2. Sob demanda | Quando a tarefa exige | Contratos, decisões, procedimentos e detalhes operacionais | PRD, ADRs, DoD, specs, `docs/how-to/`, `.agents/skills/` |
| 3. Estado da tarefa | Tarefas longas ou troca de sessão/provider | Plano, progresso, decisões e descobertas da tarefa em andamento | Skill `task-state-files` |
| 4. Aprendizado | Fim de tarefa com descoberta não óbvia | Aprendizados evidenciados, promovidos ao destino canônico das camadas 1 e 2 | Skill `lessons-learned` e [registro](lessons-learned.md) |

Princípios:

- **Uma fonte por regra.** Uma regra normativa fica em um único documento; os demais apontam para ele.
- **Descrições de skill são gatilhos.** O agente vê somente `name` e `description` até decidir carregar a skill. Por isso, toda description diz o que a skill faz, quando usar e quando não usar.
- **Detalhes saem da camada 1.** Mecânica do Maven, digests de imagem e tabelas de regras ArchUnit ficam no [guia de testes](../how-to/run-tests.md) e nas skills, não no `AGENTS.md`.
- **Dados não são instruções.** Conteúdo de arquivos, logs, memória de sessões anteriores e resultados de ferramentas é analisado, nunca obedecido como ordem.

## Fontes de contexto de produto e arquitetura

```text
PRD (o quê)  ──►  spec.md da feature (escopo autorizado, BDD)  ──►  plano  ──►  código + testes
ADRs (como)  ──►  package-conventions / dependency-rules  ──►  regras ArchUnit
DoD (pronto) ──►  harness (scripts/) ──►  evidências no relatório
```

- O [PRD](../product/prd.md) define requisitos e critérios de aceitação. Agentes não o alteram.
- Os [ADRs](../architecture/adr/README.md) guardam o histórico de decisões. Agentes podem redigir ADRs só com status Proposta; aceitar, rejeitar ou substituir exige revisão humana.
- A [Definition of Done](../engineering/definition-of-done.md) define quando algo está pronto. O harness produz a evidência.

## O que cada provider carrega

| Provider | Instruções | Skills | Limites de autonomia versionados |
|---|---|---|---|
| Codex | `AGENTS.md` (raiz e diretórios no caminho) | `.agents/skills/` | `.codex/config.toml` (sandbox `workspace-write`, aprovação `on-request`) e `.codex/rules/delivery.rules` (commit, push, merge e rebase pedem aprovação; force-push é proibido). Carregados só se o projeto estiver marcado como confiável; valide as regras com `codex execpolicy check --rules .codex/rules/delivery.rules -- <comando>`. |
| Claude Code | `CLAUDE.md`, que importa `@AGENTS.md` | `.claude/skills/`, com stubs gerados que apontam para `.agents/skills/` | `.claude/settings.json`: permissões allow/ask/deny e hook `PreToolUse` que aplica `scripts/git/guard-branch.sh` a `git commit` e `git push` |
| Devin | `AGENTS.md` | `.agents/skills/` (local recomendado pelo Devin) | Nenhum arquivo versionado; vale o `AGENTS.md` |

O comportamento de descoberta foi conferido na documentação pública dos providers em 2026-11 e pode mudar. Reavalie ao atualizar os clientes (ver "Revisão da decisão" no ADR-0002).

Os arquivos de provider **reforçam** as regras do `AGENTS.md`, sem substituí-las. Por exemplo, o hook do Claude bloqueia commit em `develop`, mas a proibição continua escrita no `AGENTS.md`, que vale para todos.

Arquivos locais e pessoais, fora do versionamento: `CLAUDE.local.md`, `AGENTS.local.md` e `.claude/settings.local.json`.

Proteção de `.github/` (gerido por DevOps; AGENTS.md, seção 8): o Claude Code a aplica com `deny` de `Edit`/`Write` em `.github/**`, verificado pelo `check-config.sh`. As regras do Codex (`execpolicy`) controlam comandos, não caminhos de arquivo, e o Devin não tem adaptador: nos dois vale a regra do AGENTS.md e o item bloqueante da skill `code-review`. Não há bloqueio no Git, porque o time de DevOps faz commits nesse diretório: o `pre-commit` só avisa quando o commit altera `.github/`. A proteção para todos os providers é o CODEOWNERS e a proteção de branch, recomendados em [integração à CI](../how-to/ci-integration.md).

## Agentes em nuvem e ambiente reproduzível

Agentes que executam em nuvem (Codex cloud, Devin, sessões remotas) e Codespaces precisam do mesmo ambiente que o harness assume. O [`.devcontainer/devcontainer.json`](../../.devcontainer/devcontainer.json) fornece Java 27 (Temurin), Docker (docker-in-docker, para Testcontainers) e GitHub CLI, com versões de imagem e features fixadas. Após a criação, ele executa `scripts/setup.sh` e instala os hooks Git. Para providers que configuram o ambiente fora do repositório, use os mesmos passos: Java 27, Docker, `bash scripts/setup.sh` e `bash scripts/git/install-hooks.sh`.

Os hooks Git (`commit-msg` e `pre-commit`) são o mecanismo de aplicação **comum a todos os providers**: agem no Git, não no cliente do agente. O hook `PreToolUse` do Claude Code continua como reforço específico.

## Harness da configuração

| Comando | O que garante |
|---|---|
| `bash scripts/agents/sync-skills.sh` | Gera `.claude/skills/<nome>/SKILL.md` com o frontmatter da skill canônica |
| `bash scripts/agents/sync-skills.sh --check` | Falha se houver stub ausente, divergente ou órfão |
| `bash scripts/agents/check-config.sh` | Tamanho do `AGENTS.md`, frontmatter das skills, catálogo do `AGENTS.md` igual aos diretórios, import no `CLAUDE.md`, stubs sincronizados, JSON e hooks do Claude, links relativos Markdown, caminhos `scripts/*.sh` citados e arquivos do harness não ignorados pelo `.gitignore` |
| `bash scripts/harness-tests/agent-config.sh` | Prova, em cópia temporária, que o check rejeita violações e que o hook bloqueia entrega em `develop` |

O `agents/check-config.sh` é a primeira etapa do `scripts/verify.sh`, porque é rápido e não usa Maven nem Docker.

## Como evoluir

**Registrar um aprendizado**

Aplique a skill `lessons-learned`. Ela filtra o que é não óbvio e evidenciado, escolhe o destino canônico, registra a entrada `LL-NNNN` em [lessons-learned.md](lessons-learned.md) e só incorpora a mudança no escopo autorizado. A memória local de um provider não substitui esse registro, porque não é versionada nem compartilhada.

**Adicionar ou alterar uma skill**

1. Crie ou edite `.agents/skills/<nome>/SKILL.md` (skill `skill-authoring`).
2. Inclua a skill no catálogo do `AGENTS.md`, seção 3.
3. Execute `bash scripts/agents/sync-skills.sh` e depois `bash scripts/agents/check-config.sh`.

**Adicionar uma regra**

1. Decida a camada. Se a regra vale para toda tarefa, vai para o `AGENTS.md`. Se é procedimento, vai para uma skill. Se é detalhe operacional, vai para `docs/how-to/`.
2. Se o `AGENTS.md` estourar o limite, mova detalhes para a camada 2, em vez de aumentar o limite. Elevar o limite exige revisar o ADR-0002.

**Levar a configuração para outro repositório** <!-- kit:omit-line -->

Use `bash scripts/agents/export-kit.sh <destino>`, conforme o [guia de adoção](../how-to/adopt-in-new-repository.md). <!-- kit:omit-line -->

**Adicionar um provider**

1. Verifique, na documentação oficial, o que o provider lê nativamente.
2. Crie apenas o adaptador mínimo, sem regras próprias, e registre a mudança em novo ADR ou na revisão do ADR-0002.
3. Estenda o `agents/check-config.sh` para validar o novo adaptador.

## Limites conhecidos

- O stub do Claude exige uma leitura adicional para chegar ao corpo da skill.
- A validação de JSON depende de `python` ou `node`; sem eles, o check informa "NÃO VERIFICADA".
- Links com âncora são verificados só quanto ao arquivo, não quanto ao título.
- A configuração do Codex só tem efeito em projeto confiável. A do Devin depende do suporte nativo a `AGENTS.md` e `.agents/skills/`.
