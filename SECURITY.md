# Política de segurança

## Versões suportadas

| Versão | Suportada |
|---|---|
| `develop` (branch de integração) | ✅ |
| Branches de trabalho e versões anteriores | ❌ |

O projeto ainda não publica releases. Correções de segurança entram em `develop`.

## Como reportar uma vulnerabilidade

**Não abra issue pública** para vulnerabilidades.

Use o reporte privado do GitHub: na aba **Security** do repositório, escolha **Report a vulnerability** ([GitHub Security Advisories](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability)). Informe:

- componente e versão (commit) afetados;
- passos para reproduzir e impacto esperado;
- evidências, sem incluir credenciais reais ou dados pessoais.

O responsável confirma o recebimento, avalia o impacto e combina com você a divulgação depois que a correção estiver disponível.

## Escopo

Dentro do escopo:

- código da aplicação-exemplo (`src/`), migrações e configuração;
- scripts do harness (`scripts/`) e configuração de agentes (`.agents/`, `.claude/`, `.codex/`), inclusive instruções que possam induzir um agente a ações inseguras (prompt injection por arquivos do repositório).

Fora do escopo: vulnerabilidades em dependências de terceiros sem impacto demonstrado neste projeto (reporte ao projeto de origem) e ambientes locais mal configurados.

## Práticas do repositório

- Segredos nunca são versionados ([AGENTS.md, seção 8](AGENTS.md#8-segurança-e-autonomia)). A varredura `bash scripts/security/scan-secrets.sh` usa gitleaks e roda também no hook `pre-commit` (`bash scripts/git/install-hooks.sh`).
- Mudanças com entrada externa, SQL, logs, configuração ou novas dependências passam pela skill [security-review](.agents/skills/security-review/SKILL.md).
- Se um segredo for exposto, revogue-o imediatamente: remover do histórico não basta.
