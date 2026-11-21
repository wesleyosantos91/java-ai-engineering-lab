# ADR-0002: Contexto de agentes multi-provider

- **Status:** Proposta
- **Data:** 2026-11-20
- **Responsável pela decisão:** Wesley Oliveira Santos
- **Substitui:** —
- **Substituído por:** —
- **Relacionados:** [ADR-0001](0001-architecture-principles.md), seção AI-First

## Contexto

O ADR-0001 determina manter instruções versionadas para agentes. O repositório precisa funcionar com Codex, Claude Code e Devin sob as mesmas regras, para que o comportamento dos agentes seja consistente e reproduzível independentemente do provider ([ADR-0004](0004-ai-first-reference-repository.md)). <!-- kit:replace-line: O ADR-0001 determina manter instruções versionadas para agentes. O repositório precisa funcionar com Codex, Claude Code e Devin sob as mesmas regras, para que o comportamento dos agentes seja consistente e reproduzível independentemente do provider. -->

Os providers descobrem contexto de formas diferentes (comportamento observado na documentação pública em 2026-11):

| Provider | Instruções sempre carregadas | Skills |
|---|---|---|
| Codex | `AGENTS.md` | `.agents/skills/` |
| Devin | `AGENTS.md` | `.agents/skills/` (local recomendado), além de outros diretórios de providers |
| Claude Code | `CLAUDE.md` (sem `CLAUDE.md`, pode recorrer ao `AGENTS.md`) | `.claude/skills/` |

Manter cópias independentes por provider cria divergência de regras. O `AGENTS.md`, com cerca de 22 KB, também ocupa contexto em toda sessão, com detalhes que só importam em tarefas específicas.

## Decisão

1. **Fonte canônica única.** `AGENTS.md` e `.agents/skills/` contêm todas as regras e procedimentos. Arquivos de provider são adaptadores sem regras próprias.
2. **Adaptador do Claude Code.** `CLAUDE.md` importa `@AGENTS.md`. `.claude/skills/<nome>/SKILL.md` são stubs gerados por `scripts/agents/sync-skills.sh`, com o mesmo `name` e `description` da skill canônica e corpo que apenas a referencia.
3. **Codex e Devin** usam os arquivos canônicos nativamente. Não se criam adaptadores de conteúdo para eles.
4. **Limites de autonomia por provider** são configurados apenas onde o provider oferece mecanismo versionável: `.claude/settings.json` (permissões e hook que delega a `scripts/git/guard-branch.sh`) e `.codex/config.toml` mais `.codex/rules/` (sandbox, aprovações e regras de comando). Esses mecanismos reforçam as regras do `AGENTS.md`, mas não as substituem.
5. **Contexto em camadas.** O `AGENTS.md` é um roteador enxuto, com limite verificado de 12 KB: regras invioláveis, mapa de contexto e catálogo de skills. Detalhes operacionais ficam em `docs/how-to/` e nas skills, carregados sob demanda.
6. **Verificação automatizada.** `scripts/agents/check-config.sh` valida frontmatter, paridade dos stubs, catálogo de skills, import do `CLAUDE.md`, links relativos, tamanho do `AGENTS.md` e configurações. Ele integra o `scripts/verify.sh`.

## Alternativas consideradas

- **Symlink `.claude/skills → .agents/skills`:** não adotado. No Windows, depende de `core.symlinks` e do modo de desenvolvedor, e falha silenciosamente como arquivo de texto em clones sem suporte.
- **Cópia integral das skills:** não adotada. Duplica cerca de 1.700 linhas e torna a divergência de conteúdo provável.
- **Arquivos de instruções independentes por provider:** não adotados. Fazem as regras divergirem entre providers e multiplicam a manutenção.
- **Manter o `AGENTS.md` integral:** não adotado. Repete o guia de testes e consome contexto sem necessidade.

## Consequências positivas

- Uma alteração de regra ocorre em um único lugar e vale para os três providers.
- A divergência entre os adaptadores e a fonte canônica é detectada pelo harness.
- Menor consumo de contexto fixo por sessão.

## Consequências negativas

- É preciso executar `bash scripts/agents/sync-skills.sh` ao criar ou alterar a description de uma skill.
- O stub do Claude exige uma leitura adicional para carregar o corpo da skill.
- O comportamento de descoberta dos providers muda com o tempo e exige revisão periódica.

## Validação

- `bash scripts/agents/check-config.sh` e `bash scripts/harness-tests/agent-config.sh`.
- Verificação manual por provider: skills listadas e `AGENTS.md` carregado na sessão.

## Revisão da decisão

Revisar quando um provider passar a descobrir `.agents/skills/` nativamente (o adaptador correspondente pode ser removido), quando um novo provider for adotado ou quando o limite de tamanho do `AGENTS.md` se mostrar inadequado.
