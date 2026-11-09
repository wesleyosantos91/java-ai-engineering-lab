---
name: quality-gates
description: >-
  Orienta a configuração, execução e interpretação dos quality gates do Java AI
  Engineering Lab: JaCoCo (linhas e branches), PIT (mutation score) e ArchUnit. Use ao
  configurar uma dessas ferramentas, ao avaliar cobertura ou qualidade de testes, ou
  ao relatar o status dos gates. Não use para reduzir limites, ampliar exclusões ou
  declarar gates aprovados sem execução real.
---

# Quality Gates

## Estado atual

JaCoCo, PIT e ArchUnit **não estão configurados** no `pom.xml` nem integrados ao harness `scripts/`. Até sua configuração e validação operacional, qualquer status de gate é **NOT RUN**, e eles não são obrigatórios, conforme a [DoD](../../../docs/engineering/definition-of-done.md).

## Metas aprovadas

| Gate | Meta |
|---|---|
| JaCoCo — linhas elegíveis | ≥ 90% |
| JaCoCo — branches elegíveis | ≥ 90% |
| PIT — mutation score | ≥ 90% |
| ArchUnit | Nenhuma violação das [regras de dependência](../../../docs/architecture/dependency-rules.md) |

As metas vêm do [AGENTS.md, seção 6](../../../AGENTS.md); não as altere.

## Configuração (quando autorizada)

1. Trate como alteração de build: exige autorização, branch própria e commit `build(maven): ...`.
2. Adicione os plugins com versões explícitas e justificativa; o ArchUnit entra como dependência de teste.
3. Defina exclusões de forma explícita e justificada, como a classe `main` gerada; nunca exclua código para alcançar a meta.
4. Codifique as regras ArchUnit a partir dos documentos de arquitetura, uma regra por restrição documentada.
5. Integre ao harness com um script dedicado e atualize o AGENTS.md e a documentação com a [skill project-documentation](../project-documentation/SKILL.md).
6. Valide: execute com sucesso e também demonstre que o gate falha quando a meta é violada.

## Interpretação

- Cobertura alta não prova testes bons; mutation score é o melhor indicador da força das asserções.
- Mutantes sobreviventes indicam asserções ausentes ou fracas: melhore os testes, não as exclusões.
- Violação de ArchUnit é defeito de arquitetura: corrija o código ou solicite decisão via ADR.

## Proibições

Reduzir limites, excluir pacotes, usar `@Disabled` ou suprimir regras para aprovar um gate.
