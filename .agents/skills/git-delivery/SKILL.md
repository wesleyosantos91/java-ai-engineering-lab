---
name: git-delivery
description: >-
  Prepara commits e pull requests do Java AI Engineering Lab com branch correta,
  verificação local, commits pequenos em Conventional Commits e descrição com
  evidências. Use somente quando o usuário autorizar commit, push ou abertura de PR.
  Não use para merge, rebase destrutivo ou force-push sem autorização explícita.
---

# Git Delivery

## Fonte de verdade

As regras de branches e commits estão no [AGENTS.md, seção 9](../../../AGENTS.md). Esta skill define a sequência de execução.

## Antes do commit

1. Confirme a autorização explícita para a operação pedida: commit, push ou PR são autorizações distintas.
2. Execute `bash scripts/git/guard-branch.sh`; ele bloqueia `develop`, `main` e `master`. Se necessário, crie uma branch `feature/*`, `fix/*` ou `experiment/*`.
3. Confirme que a verificação adequada foi executada, conforme a [skill verification-before-completion](../verification-before-completion/SKILL.md).
4. Revise `git status`, `git diff` e `git diff --cached`; execute `git diff --check` e `git diff --cached --check`.
5. Agrupe os arquivos por objetivo; mudanças independentes viram commits separados.
6. Prepare arquivos explicitamente pelo caminho, sem `git add -A` às cegas, e verifique se não há artefatos como `target/` ou `.idea/`. Execute `bash scripts/security/scan-secrets.sh` (ou `--staged`) quando a mudança tocar configuração, credenciais ou dados.

## Mensagem de commit

- Formato `<type>(<scope>): <description>`, em inglês, no imperativo, sem ponto final.
- Tipos permitidos: `feat`, `fix`, `docs`, `test`, `refactor`, `perf`, `build`, `ci`, `chore`, `style` e `revert`.
- Scope opcional, usado quando ajuda a identificar a área afetada.
- Breaking change: `!` após o tipo ou scope (por exemplo, `feat(api)!: change product response contract`), documentando a incompatibilidade e a justificativa no corpo.
- Siga a proibição de coautoria definida no [AGENTS.md, seção 9](../../../AGENTS.md): nenhum trailer `Co-Authored-By` nem atribuição a pessoas, agentes, modelos ou ferramentas de IA, mesmo que o cliente do agente sugira incluí-la.

Exemplos válidos:

```text
feat(product): add product creation endpoint
fix(product): prevent duplicate SKU creation
docs(architecture): define package conventions
test(product): cover concurrent product creation
refactor(product): simplify product mapping
perf(database): optimize product listing query
build(maven): configure jacoco and pit
chore: update repository configuration
```

Antes de confirmar o commit, verifique que os arquivos preparados pertencem à mesma mudança e que a mensagem é válida:

- Com os hooks instalados (`bash scripts/git/install-hooks.sh`; `bash scripts/git/install-hooks.sh --status` informa), o `commit-msg` rejeita formato inválido e coautoria, e o `pre-commit` aplica o guard de branch, o check de configuração de agentes, `git diff --cached --check` e a varredura de segredos. Nunca use `--no-verify` para contorná-los.
- Sem hooks, ou antes de abrir o PR, valide os commits da branch: `bash scripts/git/check-commit-msg.sh --range develop..HEAD`.
- O script não verifica se a descrição está em inglês e no imperativo; confira isso manualmente.

## Pull request

- Base: `develop`, salvo instrução diferente.
- Corpo: objetivo, escopo e referência da spec, alterações principais, verificações executadas com resultados reais, limitações e pendências.
- Não declare gates ou testes aprovados que não foram executados.

## Proibições

Commit direto em `develop`, push, merge, force-push, `--no-verify` ou reescrita de histórico publicado sem autorização explícita.
