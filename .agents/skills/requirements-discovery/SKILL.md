---
name: requirements-discovery
description: >-
  Esclarece intenção, problema, regras e limites de uma demanda antes de qualquer
  especificação ou código no Java AI Engineering Lab. Use quando a solicitação for
  vaga, incompleta, ambígua ou envolver regra de produto não definida no PRD. Não use
  para demandas já especificadas e aprovadas; nesse caso siga feature-delivery.
---

# Requirements Discovery

## Objetivo e limites

Transformar uma ideia em entendimento verificável antes da especificação. A descoberta não autoriza implementação, não cria requisitos por suposição e não altera o [PRD aprovado](../../../docs/product/prd.md). A governança permanece no [catálogo de features](../../../docs/features/README.md).

## Procedimento

1. Leia apenas as seções do PRD e as especificações relacionadas à demanda.
2. Reformule o pedido em uma frase: problema, usuário afetado e resultado esperado.
3. Separe o que já está decidido (PRD, ADR, spec), o que está implícito e o que está indefinido.
4. Faça perguntas objetivas somente sobre decisões materialmente relevantes, em grupos curtos, oferecendo opções com trade-offs e uma recomendação.
5. Explore casos de sucesso, erro, limites, concorrência, segurança e dados existentes.
6. Proponha duas ou três abordagens quando houver escolha real, com impacto em escopo, risco e custo.
7. Registre o que ficou fora do escopo, evitando ampliar a demanda (YAGNI).

## Saída esperada

Um resumo com problema, objetivo, regras confirmadas, decisões pendentes, itens fora do escopo e esboço de cenários BDD. Esse resumo alimenta a [skill spec-driven-development](../spec-driven-development/SKILL.md).

## Sinais de parada

- Conflito com o PRD ou ADR aceito: reporte e solicite decisão técnica.
- Resposta que altere contrato aprovado: trate como mudança de escopo pelo procedimento do catálogo.
