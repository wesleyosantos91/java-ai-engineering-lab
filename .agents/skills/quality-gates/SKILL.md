---
name: quality-gates
description: >-
  Orienta a execução, interpretação e manutenção dos quality gates do Java AI
  Engineering Lab: JaCoCo (linhas e branches), PIT (mutation score) e ArchUnit. Use ao
  executar ou relatar os gates, avaliar cobertura ou força dos testes, adicionar regras
  arquiteturais ou ajustar a configuração das ferramentas. Não use para reduzir
  limites, ampliar exclusões ou declarar gates aprovados sem execução real.
---

# Quality Gates

## Estado atual

Os três gates estão configurados no `pom.xml` e integrados ao harness. No scaffold atual, sem código de negócio, eles retornam **SKIP**, o que não equivale a aprovação. A capacidade de rejeitar violações foi demonstrada em cópia isolada por `scripts/tests/test-quality-gates.sh`. Comandos, relatórios e diagnóstico estão no [guia de testes](../../../docs/how-to/run-tests.md#quality-gates).

| Gate | Meta | Script | Fluxo |
|---|---|---|---|
| ArchUnit 1.5.1 | Nenhuma violação das [regras de dependência](../../../docs/architecture/dependency-rules.md) | `bash scripts/test-architecture.sh` | `verify.sh` |
| JaCoCo 0.8.16 — LINE | ≥ 90% | `bash scripts/test-coverage.sh` | `verify.sh`, após as suítes |
| JaCoCo 0.8.16 — BRANCH | ≥ 90% | `bash scripts/test-coverage.sh` | `verify.sh`, após as suítes |
| PIT 1.30.1 | Mutation score ≥ 90% | `bash scripts/test-mutation.sh` | Execução explícita |

As metas vêm do [AGENTS.md, seção 6](../../../AGENTS.md); não as altere. A obrigatoriedade segue a [DoD](../../../docs/engineering/definition-of-done.md).

## Executar

```bash
bash scripts/verify.sh          # build, unitários, arquitetura, integração e cobertura
bash scripts/test-mutation.sh   # mutação; necessária para os quality gates completos
```

Códigos de saída: `0` PASS, `3` SKIP e `1` FAIL. Relate cada gate separadamente. `verify.sh` com exit `0` e mutação NOT RUN não é aprovação integral.

## Interpretar

- **SKIP por ausência:** sem código, classes, branches ou mutantes elegíveis. Informe a causa; não trate como PASS.
- **ArchUnit SKIP parcial:** algumas regras não têm classes elegíveis (testes ignorados). O resumo mostra `total` e `skipped`.
- **Cobertura FAIL "sem dados":** há código elegível, mas não há `.exec` das suítes. Execute `verify.sh`, que gera os dados na mesma execução.
- **Mutantes sobreviventes:** indicam asserções ausentes ou fracas. Melhore os testes, não as exclusões.
- **NO_COVERAGE no PIT:** código não exercitado por testes `*Test`. O PIT não executa `*IT`.
- **Violação ArchUnit:** é defeito de arquitetura. Corrija o código ou solicite decisão via ADR.
- Cobertura alta não prova testes bons; o mutation score mede melhor a força das asserções.

## Manter

1. Mudanças de versão, escopo, exclusão ou regra são alterações de build: exigem justificativa, revisão humana e commit `build(...)` ou `test(...)`.
2. Nova regra ArchUnit: derive-a de um documento de arquitetura, cite a fonte e use `checkWhenEligible` para que a ausência de classes gere SKIP.
3. Escopo do PIT (`targetClasses`) e exclusão do JaCoCo também aparecem em `test-mutation.sh` e `test-coverage.sh`; mantenha-os sincronizados.
4. Após qualquer mudança, execute `bash scripts/tests/test-quality-gates.sh` e `bash scripts/tests/test-harness.sh`.

## Proibições

Reduzir limites, ampliar exclusões ou o escopo para alcançar meta, usar `@Disabled`, suprimir regras, escrever testes sem asserções relevantes ou declarar gate aprovado com SKIP ou NOT RUN.
