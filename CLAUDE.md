# CLAUDE.md

Adaptador do Claude Code ([ADR-0002](docs/architecture/adr/0002-multi-provider-agent-context.md)). As regras canônicas estão no `AGENTS.md`, importado abaixo. Não adicione regras neste arquivo.

@AGENTS.md

## Notas do adaptador

- As skills canônicas estão em `.agents/skills/`. Os arquivos em `.claude/skills/` são stubs gerados por `bash scripts/agents/sync-skills.sh`; não os edite.
- `.claude/settings.json` reforça os limites de autonomia: comandos de entrega pedem confirmação, e o hook `scripts/agents/hooks/claude-pre-bash.sh` aplica `scripts/git/guard-branch.sh` antes de `git commit` e `git push`.
- Preferências pessoais ficam em `CLAUDE.local.md` e `.claude/settings.local.json`, ambos fora do versionamento.
