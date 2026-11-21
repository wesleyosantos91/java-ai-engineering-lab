# Integrar o harness à CI

Guia para o time de DevOps, que é dono de `.github/` ([layout do repositório](../architecture/repository-layout.md)). O harness oferece um ponto de entrada estável. O workflow só precisa chamá-lo e publicar os relatórios. Os agentes não escrevem workflows.

## Ponto de entrada

```bash
bash scripts/ci.sh
```

| Etapa | O que roda | Status |
|---|---|---|
| verify | `scripts/verify.sh`: configuração de agentes, build, unitários, arquitetura, integração (Docker) e cobertura | Por etapa: PASS, SKIP, FAIL ou NOT RUN |
| Mutação | `scripts/quality/mutation.sh` (PIT), só se o verify não falhou | PASS, SKIP, FAIL ou NOT RUN |
| Segredos | `scripts/security/scan-secrets.sh` na árvore inteira | PASS, SKIP (sem gitleaks e sem Docker) ou FAIL |

| Variável | Efeito |
|---|---|
| `CI_MUTATION=0` | Omite a mutação (registrada como NOT RUN) |
| `CI_SECRETS=0` | Omite a varredura de segredos (NOT RUN) |
| `CI_REQUIRE_COMPLETE=1` | Resultado PARCIAL também falha a CI |
| `SKIP_INTEGRATION=1` | Repassado ao `verify.sh`; só com justificativa, e o resultado fica PARCIAL |

**Retorno:** `1` quando alguma etapa falha (ou com `CI_REQUIRE_COMPLETE=1` e resultado PARCIAL); `0` nos demais casos. PARCIAL significa que há SKIP ou NOT RUN, e **SKIP não equivale a PASS**: com os gates ainda opcionais (`QUALITY_GATES=optional` no `.harness`), o esperado é PARCIAL até que sejam ativados.

**Execuções simultâneas:** o harness usa uma trava por repositório (`scripts/lib/lock.sh`). Uma segunda execução no mesmo diretório falha na hora e informa o PID da que está rodando. Em CI, cada job usa o próprio checkout.

## Resumo legível por máquina

O `verify.sh` grava `<APP_DIR>/target/harness/verify-summary.json`, e o `ci.sh` grava `<APP_DIR>/target/harness/ci-summary.json`. Em projetos, `<APP_DIR>` é `app/`.

```json
{
  "schema": 1,
  "result": "PARCIAL",
  "generated_at": "2026-11-21T21:23:20Z",
  "app_dir": "app",
  "quality_gates": "required",
  "kit_version": "2026-11-21.2a48f9b",
  "steps": {
    "agents": "PASS", "build": "PASS", "unit": "SKIP", "architecture": "PASS",
    "integration": "PASS", "coverage": "SKIP", "mutation": "SKIP", "secrets": "PASS"
  },
  "reports": ["app/target/architecture-reports", "app/target/failsafe-reports"]
}
```

`result` é `PASS`, `PARCIAL` ou `FAIL`. Cada etapa em `steps` é `PASS`, `SKIP`, `FAIL` ou `NOT RUN`. `reports` lista os diretórios de relatório que existem: JUnit XML (`surefire-reports`, `architecture-reports`, `failsafe-reports`), JaCoCo (`site/jacoco`) e PIT (`pit-reports`). A chave `schema` muda se o formato mudar de forma incompatível.

## Exemplo para GitHub Actions

Referência para o time de DevOps adaptar. Não é instalado pelo kit.

```yaml
name: ci
on:
  pull_request:
  push:
    branches: [develop]
jobs:
  harness:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: "17"   # o java.version de app/pom.xml
      - run: bash scripts/ci.sh
      - if: always()
        uses: actions/upload-artifact@v4
        with:
          name: harness-reports
          path: |
            app/target/harness/
            app/target/*-reports/
            app/target/site/jacoco/
            app/target/pit-reports/
```

Os runners `ubuntu-*` do GitHub já trazem Docker, que a integração com Testcontainers exige. O gitleaks é usado se estiver no PATH; sem ele, a varredura roda pelo Docker.

## Proteção de `.github/` e da branch

A regra de que agentes não alteram `.github/` só é bloqueada no Claude Code (`deny` no `.claude/settings.json`). No Codex e no Devin vale a regra do AGENTS.md e a revisão de código, e o `pre-commit` só avisa, porque o próprio time de DevOps faz commits nesse diretório. Para um controle que valha para todos, recomendamos ao time de DevOps:

- **CODEOWNERS** com o time como dono de `.github/`:

  ```text
  /.github/ @org/devops
  ```

- **Proteção da branch `develop`** (ou da branch de integração): pull request obrigatório, revisão obrigatória de code owners e o job que chama `scripts/ci.sh` como verificação exigida.

## Sistemas suportados

O harness roda em Bash com ferramentas GNU (coreutils, `sed`, `find`, `awk`): **Linux** (runners de CI e o `.devcontainer`) e **Windows com Git Bash**. O `bash scripts/harness-tests/linux.sh` executa os testes do harness num contêiner Linux. O macOS, que usa ferramentas BSD (`sed -i` com outra sintaxe), não é suportado sem as ferramentas GNU (por exemplo, `brew install coreutils gnu-sed findutils`, com elas antes no PATH).
