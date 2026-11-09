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
2. Execute `bash scripts/guard-branch.sh`; ele bloqueia `develop`, `main` e `master`. Se necessário, crie uma branch `feature/*`, `fix/*` ou `experiment/*`.
3. Confirme que a verificação adequada foi executada, conforme a [skill verification-before-completion](../verification-before-completion/SKILL.md).
4. Revise `git status`, `git diff` e `git diff --cached`; execute `git diff --check` e `git diff --cached --check`.
5. Agrupe os arquivos por objetivo; mudanças independentes viram commits separados.
6. Prepare arquivos explicitamente pelo caminho, sem `git add -A` às cegas, e verifique se não há segredos nem artefatos como `target/` ou `.idea/`.

## Mensagem de commit

- Formato `<type>(<scope>): <description>`, em inglês, no imperativo, sem ponto final.
- Tipos permitidos: `feat`, `fix`, `docs`, `test`, `refactor`, `perf`, `build`, `ci`, `chore`, `style` e `revert`.
- Breaking change: `!` após o tipo ou scope, com justificativa no corpo.
- Inclua as linhas de atribuição exigidas pelo cliente de IA em uso, quando houver.

## Pull request

- Base: `develop`, salvo instrução diferente.
- Corpo: objetivo, escopo e referência da spec, alterações principais, verificações executadas com resultados reais, limitações e pendências.
- Não declare gates ou testes aprovados que não foram executados.

## Proibições

Commit direto em `develop`, push, merge, force-push, `--no-verify` ou reescrita de histórico publicado sem autorização explícita.
