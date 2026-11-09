---
name: project-documentation
description: Cria, revisa e mantém documentação técnica do Java AI Engineering Lab, incluindo README, tutoriais, guias operacionais, referências de API, ADRs e explicações arquiteturais. Use quando a tarefa envolver documentação ou mudanças de código, comportamento, configuração ou comandos que exijam documentação atualizada.
---

# Project Documentation — Java AI Engineering Lab

## Objetivo

Produzir documentação técnica versionada com o código, navegável, precisa e reproduzível, com qualidade editorial inspirada em projetos open source maduros. Usar Markdown e o modelo Diátaxis; não copiar a infraestrutura editorial de outros projetos sem necessidade.

## Hierarquia de autoridade

1. Requisitos aprovados em `docs/product/prd.md` e decisões aceitas em `docs/architecture/adr/` são contratos locais. Não os altere sem autorização.
2. Código, testes, scripts e configurações são evidência do comportamento implementado, mas não autorizam alterar unilateralmente o contrato aprovado.
3. `AGENTS.md`, `docs/architecture/`, `docs/engineering/` e `README.md` orientam arquitetura, qualidade, execução e navegação.
4. Documentação externa em `references/standards.md` fornece boas práticas e referências técnicas, mas não substitui decisões do projeto.

Se contrato e implementação divergirem, reporte a divergência; não a esconda nem altere os requisitos para fazer o código parecer correto.

## Quando aplicar

- Criação e revisão de README, tutoriais, guias, referências e explicações.
- Mudanças no contrato REST, regras de negócio, arquitetura, comandos, configuração, observabilidade ou fluxo de contribuição.
- Revisão de links, exemplos, diagramas, terminologia ou documentação desatualizada.
- Produção de ADR somente quando a decisão arquitetural for autorizada; não crie ou aprove decisões unilateralmente.

## Classificação da documentação — Diátaxis

- **Tutorial** (`docs/tutorials/`): percurso guiado para aprendizagem; deve ter resultado verificável.
- **How-to** (`docs/how-to/`): instrução objetiva para concluir uma tarefa, com pré-requisitos e validação.
- **Reference** (`docs/reference/`): contratos, parâmetros, formatos e comportamentos consultáveis; sem conteúdo especulativo.
- **Explanation** (`docs/explanation/`): mecanismo causal, racional técnico, alternativas, trade-offs e riscos.

Preserve os diretórios existentes `docs/product/`, `docs/architecture/`, `docs/engineering/`, `docs/ai/` e `docs/experiments/`. Não migre documentos aprovados sem necessidade e não crie pastas vazias.

## Procedimento obrigatório

1. Identifique público, tarefa e categoria de documentação.
2. Consulte o documento existente, o código e os testes relacionados; use o mapa de `AGENTS.md`.
3. Separe comportamento implementado, requisito aprovado e capacidade futura.
4. Determine o destino do documento e atualize o índice `README.md` quando houver nova página.
5. Escreva em português brasileiro claro, com termos técnicos e identificadores em inglês quando adequados.
6. Use exemplos mínimos e realistas, compatíveis com a stack declarada; não invente comandos, retornos HTTP, saídas de build ou resultados de teste.
7. Para diagramas, descreva componentes, direção das dependências, principais falhas e limites do desenho. Prefira Mermaid quando legibilidade e manutenção justificarem.
8. Inclua links internos relativos e referências externas oficiais quando necessário. Informe versão da tecnologia quando isso for determinante. Não copie grandes trechos de terceiros.
9. Revise estrutura, links locais, blocos de código e consistência com o PRD e os ADRs.
10. Execute verificações existentes apropriadas. Para mudanças somente documentais, revise o diff e execute `git diff --check`; não alegue lint de Markdown ou verificação de links automatizados até que existam.
11. Relate arquivos atualizados, fontes consultadas, verificações executadas, lacunas e conteúdo não comprovado.

## Qualidade editorial

- Um propósito e público-alvo por página; título descritivo e hierarquia de seções coerente.
- Tutoriais e how-tos: pré-requisitos, passos, resultado esperado e troubleshooting quando aplicável.
- Referências: contratos exatos e exemplos consistentes com o código ou o PRD aprovado.
- Explicações: contexto, mecanismo, trade-offs e referências a ADRs quando relevantes.
- Evite duplicar regras normativas: prefira links para a fonte de verdade.
- Evite afirmações como "produção pronta", "testado" ou "seguro" sem evidência.
- Não atualize PRDs aprovados, ADRs aceitos nem resultados experimentais sem permissão.
- Atualize documentação junto à mudança funcional que a tornou desatualizada, respeitando o escopo autorizado.

## Referências sob demanda

Leia [padrões e referências editoriais](references/standards.md) quando definir estrutura, estilo ou citar referências externas. Não carregue todas as fontes externas automaticamente.

## Relatório de conclusão

Informe: objetivo e público, documentos criados/alterados, relações com PRD/ADR/código, fontes utilizadas, comandos realmente executados, links ou exemplos não verificados e pendências.
