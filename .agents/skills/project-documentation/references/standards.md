# Padrões e fontes externas — documentação técnica

Estas fontes são **referências de práticas editoriais**, não regras obrigatórias sobre o stack nem autorização para alterar contratos locais. Consulte versões atuais e o escopo de cada fonte ao utilizá-las.

| Referência | URL oficial | Aplicação no laboratório |
|---|---|---|
| Agent Skills specification | https://agentskills.io/specification | Formato de `SKILL.md`, metadados e carregamento progressivo |
| Diátaxis | https://diataxis.fr/ | Separação entre tutorial, how-to, referência e explicação |
| Spring Framework — CONTRIBUTING | https://github.com/spring-projects/spring-framework/blob/main/CONTRIBUTING.md | Documentação versionada com o código e exemplos verificáveis; o Spring utiliza AsciiDoc/Antora, não obrigatório neste projeto |
| Apache Flink — Documentation Style Guide | https://flink.apache.org/how-to-contribute/documentation-style-guide/ | Clareza, consistência, exemplos completos e comandos utilizáveis |
| Apache Pulsar — Documentation contribution | https://pulsar.apache.org/contribute/document-intro/ | Fluxo de contribuição e padrões de estrutura, estilo e API docs |
| Kubernetes — Documentation Style Guide | https://kubernetes.io/docs/contribute/style/style-guide/ | Linguagem consistente, padronização e revisão comunitária em projeto do ecossistema CNCF |

## Política de citação

- Prefira documentação oficial e versione a referência quando comportamento ou sintaxe forem sensíveis à versão.
- Em documentos técnicos, use links com rótulo significativo (por exemplo, `[Spring JDBC Reference](URL)`), não apenas URLs soltas.
- Ao registrar uma decisão, indique qual informação externa embasou a análise e quais trade-offs foram considerados.
- Não trate recomendações de Spring, Apache ou Kubernetes como imposições arquiteturais para o laboratório.
- Não afirme ter consultado uma fonte, executado um exemplo ou verificado um link se isso não ocorreu.
- Evite replicar textos extensos: faça síntese original e cite a fonte.
