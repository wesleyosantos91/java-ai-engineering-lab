# Como contribuir

Guia para pessoas e agentes de IA que alteram este repositório. As regras normativas estão no [AGENTS.md](AGENTS.md); este guia resume o fluxo e aponta para elas.

## Antes de começar

1. Prepare o ambiente: `bash scripts/setup.sh` (Java 27, Maven Wrapper, Docker) e instale os hooks: `bash scripts/git/install-hooks.sh`. Alternativa pronta: abra o repositório no [devcontainer](.devcontainer/devcontainer.json), que já executa os dois.
2. Localize o contrato da mudança: requisito no [PRD](docs/product/prd.md), spec no [catálogo de features](docs/features/README.md) ou decisão nos [ADRs](docs/architecture/adr/README.md). Mudança sem contrato começa pela skill `requirements-discovery`.
3. Crie uma branch a partir de `develop`: `feature/*`, `fix/*` ou `experiment/*` (spike ou prova de conceito).

## Durante o desenvolvimento

- Siga o fluxo da skill [feature-delivery](.agents/skills/feature-delivery/SKILL.md): especificação → plano → TDD → verificação → revisão.
- Respeite a arquitetura Feature-Based e as [regras de dependência](docs/architecture/dependency-rules.md). Decisão arquitetural nova exige ADR, a partir do [template](docs/architecture/adr/TEMPLATE.md).
- Testes: unitários `*Test`, arquitetura `*ArchitectureTest` e integração `*IT` ([guia de testes](docs/how-to/run-tests.md)).
- Documentação em português brasileiro; código, identificadores, branches e commits em inglês.
- Aprendizados não óbvios (falhas de ambiente, correções, comportamento de ferramentas) seguem a skill [lessons-learned](.agents/skills/lessons-learned/SKILL.md).

## Antes do pull request

```bash
bash scripts/git/guard-branch.sh     # bloqueia develop, main e master
bash scripts/git/check-commit-msg.sh --range develop..HEAD   # Conventional Commits, sem coautoria
bash scripts/security/scan-secrets.sh  # gitleaks
bash scripts/verify.sh              # configuração de agentes, build, testes, arquitetura e cobertura
bash scripts/quality/mutation.sh    # quando houver código de domínio ou service
bash scripts/performance/smoke.sh   # com a aplicação em execução, quando a mudança afetar o runtime
git diff --check
```

- Confira a [Definition of Done](docs/engineering/definition-of-done.md). `SKIP`, `NOT RUN` e resultado PARCIAL não são aprovação.
- Commits em [Conventional Commits](https://www.conventionalcommits.org/), em inglês, no imperativo e sem ponto final, por exemplo `feat(product): add product creation endpoint`. Não inclua `Co-Authored-By` nem outra atribuição de coautoria. Os hooks aplicam essas regras a cada commit; não use `--no-verify`. Detalhes na skill [git-delivery](.agents/skills/git-delivery/SKILL.md).
- Abra o PR contra `develop` e preencha o [template](.github/pull_request_template.md) com as verificações realmente executadas. <!-- kit:replace-line: - Abra o PR contra `develop` e preencha o template de PR do repositório (mantido pelo time de DevOps em `.github/`) com as verificações realmente executadas. -->

## Segurança

Vulnerabilidades são reportadas de forma privada, conforme o [SECURITY.md](SECURITY.md). Nunca versione segredos.

## Licença

Ao contribuir, você concorda que sua contribuição seja licenciada sob a [Apache License 2.0](LICENSE), conforme a seção 5 da licença. <!-- kit:replace-line: [PREENCHER: licença do projeto e termos das contribuições]. -->

## Revisão humana

Aceitar ADRs, marcar features como Concluídas, alterar o PRD e fazer merge exigem revisão humana. Agentes não executam commit, push ou merge sem autorização explícita.
