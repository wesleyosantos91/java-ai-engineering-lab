# Layout do repositório

A configuração AI-First fica na **raiz** e vale para o repositório inteiro: os agentes podem alterar qualquer diretório, não só o código Java. Os diretórios de projeto não recebem instruções, skills nem scripts próprios.

## Diretórios

| Diretório | Conteúdo | Consumido por | Agentes podem alterar? |
|---|---|---|---|
| Raiz: `AGENTS.md`, `CLAUDE.md`, `.agents/`, `.claude/`, `.codex/` | Instruções, skills e adaptadores de provider | Agentes de IA | Só com autorização, seguindo a skill `skill-authoring` e o `check-config` |
| `docs/` | PRD, ADRs, specs de feature e guias | Pessoas e agentes | Sim, conforme a skill `project-documentation`; PRD aprovado e ADR aceito não |
| `scripts/` e `.harness` | Harness local e configuração dele | Pessoas, agentes e hooks Git | Só com autorização; nunca para obter aprovação artificial |
| `app/` | Projeto Maven (`app/pom.xml`, `app/src/`); o harness o localiza por `APP_DIR` no `.harness` | Maven, harness e pipelines | Sim, dentro do escopo autorizado |
| `infra/` | Infraestrutura como código, compose e configuração de ambiente | Pipelines e time de plataforma | Só dentro do escopo autorizado (AGENTS.md, seção 8) |
| `tests/` | Testes fora do app (por exemplo, `tests/performance/k6/`) | Harness e pipelines | Sim, dentro do escopo autorizado |
| `.github/` | Workflows, CODEOWNERS e templates | GitHub Actions e GitHub | **Não**: gerido por DevOps. Proponha a mudança ao time responsável |

Neste repositório de referência, o projeto Maven fica na raiz (`.harness` com `APP_DIR=.`). Em projetos criados pelo [kit ou pelo seed](../how-to/adopt-in-new-repository.md), ele fica sempre em `app/`. <!-- kit:replace-line: O projeto Maven fica sempre em `app/` (`app/pom.xml`; `.harness` com `APP_DIR=app`). -->

## Regras e verificações por diretório

| Regra | Verificação automática | Limite |
|---|---|---|
| Nenhum segredo em qualquer diretório | `scripts/security/scan-secrets.sh` (gitleaks) varre a árvore inteira, também no `pre-commit` | Só detecta padrões conhecidos |
| Build, testes e gates do app | `scripts/verify.sh` executa o Maven em `APP_DIR`; `QUALITY_GATES` no `.harness` define se gate ausente no pom é FAIL (`required`) ou SKIP (`optional`) | — |
| `.github/` não é alterado por agentes | `deny` de `Edit`/`Write` em `.github/**` no `.claude/settings.json`, conferido pelo `check-config`; item bloqueante na skill `code-review` | Codex e Devin não têm bloqueio por caminho no repositório: vale a regra do AGENTS.md e a revisão. Não há bloqueio no Git, porque o time de DevOps faz commits nesse diretório |
| `infra/` e `tests/` só dentro do escopo | Revisão (skill `code-review`) | Sem verificação automática de escopo |
