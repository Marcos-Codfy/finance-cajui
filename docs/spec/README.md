# Especificação funcional

Fase 2 do projeto. O Cajui segue desenvolvimento orientado a especificação: estes documentos decidem o que o código faz, e nenhuma tela é implementada antes de o que ela precisa cumprir estar escrito aqui.

Todos os exemplos numéricos usam o mesmo cenário — **setembro de 2026** — descrito em [rules/indicators.md](rules/indicators.md#exemplo-completo). A aritmética dele foi conferida por script e vira a base dos testes do domínio.

## Por onde começar

| Se você quer entender… | Leia |
|---|---|
| O que o app resolve e por que o cartão não é despesa | [problem.md](problem.md) |
| O que cada palavra significa, no código e na tela | [glossary.md](glossary.md) |
| Quem usa e em que momentos | [personas-and-journeys.md](personas-and-journeys.md) · [journeys.md](journeys.md) |
| O que é sempre verdade no sistema | [rules/](rules/README.md) — 345 regras numeradas |
| O que o usuário faz, com critérios de aceite | [use-cases.md](use-cases.md) — 65 casos em 9 áreas |
| Como os dados são guardados | [data-model.md](data-model.md) |
| O requisito crítico: compartilhar um comprovante | [sharing-flow.md](sharing-flow.md) |
| O retorno diário, semanal e mensal | [feedback.md](feedback.md) |
| A conversa com IA | [assistant.md](assistant.md) · [assistant-conversations.md](assistant-conversations.md) |
| Quão rápido, seguro e acessível precisa ser | [non-functional.md](non-functional.md) · [segurança e privacidade](non-functional-security.md) · [acessibilidade](non-functional-accessibility.md) — 134 requisitos com alvo e forma de medir |

## Regras de negócio

| Faixa | Área | Arquivo |
|---|---|---|
| RN-1xx | Dinheiro, renda e as duas moedas | [income-and-tenders.md](rules/income-and-tenders.md) |
| RN-2xx | Lançamentos e pagamentos | [entries-and-payments.md](rules/entries-and-payments.md) |
| RN-3xx | Cartão de crédito | [credit-card.md](rules/credit-card.md) |
| RN-4xx | Blocos e orçamento | [blocks-and-budget.md](rules/blocks-and-budget.md) |
| RN-5xx | Dívidas | [debts.md](rules/debts.md) |
| RN-6xx | Indicadores | [indicators.md](rules/indicators.md) |
| RN-7xx | Captura e classificação | [capture-and-classification.md](rules/capture-and-classification.md) |
| RN-8xx | Retorno periódico | [feedback.md](rules/feedback.md) |
| RN-9xx | Assistente e privacidade | [assistant-and-privacy.md](rules/assistant-and-privacy.md) |

## Rastreabilidade

```
pedido original ─┐
decisão do dono ─┼─▶ RN-NNN ─▶ UC-ÁREA-NN ─▶ teste nomeado pelo ID
pesquisa (D-…)  ─┘      │
                        └────▶ RNF-ÁREA-NN ─▶ asserção de CI ou item de checklist
```

Toda regra diz de onde veio. Todo caso de uso diz que regras usa e que evento grava. Todo requisito não-funcional diz como se mede e em que fase. A Fase 6 fecha o ciclo: o identificador aparece no nome do teste.

## Decisões já tomadas

| Data | Decisão | Onde está |
|---|---|---|
| 2026-09-19 | Android é o app de uso; a web é modo consulta | [problem.md](problem.md#fora-do-escopo) |
| 2026-09-19 | Cartão híbrido: à vista conta na data da compra; parcelada, no mês de cada parcela | RN-310, RN-311 |
| 2026-09-19 | O vale acumula e nunca se soma ao dinheiro | RN-111, RN-121 |
| 2026-09-19 | Semana de calendário, com o limite recalculado por dias | RN-641, RN-644 |
| 2026-09-19 | Web com `noindex`; SEO do Lighthouse vira exceção documentada | [non-functional.md](non-functional.md#exceções-e-riscos-aceitos) |

## Para validar neste checkpoint

Decisões de modelagem que não vieram de um pedido explícito. Cada uma está marcada com **⚑ validar** no lugar onde aparece, e vale como proposta até a aprovação.

### Dinheiro e cartão

| # | Proposta | Onde |
|---|---|---|
| 1 | **Compra parcelada no cartão entra no bloco de dívidas**, como compromisso com fim. Conta no "% comprometido com dívidas" e não consome o limite semanal | RN-312, RN-503, RN-633 |
| 2 | **O dia de fechamento é o primeiro dia do ciclo novo**: compra feita no dia de fechamento já cai na fatura seguinte | RN-303 |
| 3 | **Gasto fora do padrão não consome o limite da semana**; conta só no resultado do mês. Sem isso, um conserto de R$ 700 faria o painel abrir com a semana R$ 504 acima do limite | RN-648 |
| 4 | **Falta do mês não vira dívida automática** nem é descontada do mês seguinte: é informada, e o que fazer é decisão sua | RN-443 |
| 5 | O app **sugere** uma provisão mensal para gastos fora do padrão, pela média de 12 meses | RN-432 |

### Captura

| # | Proposta | Onde |
|---|---|---|
| 6 | O **comprovante original** é guardado no aparelho na hora e enviado ao seu servidor quando há rede. A imagem nunca vai para a IA | [data-model.md](data-model.md#comprovantes--validar), RN-724 |
| 7 | Em categoria elegível e com saldo de vale, a confirmação **pergunta se parte foi paga no vale** — o comprovante do Pix só mostra a parte em dinheiro | Q4 |
| 8 | Na segunda correção da mesma regra aprendida, oferecer **"perguntar sempre para este lugar"** | Q8 |

### Retorno

| # | Proposta | Onde |
|---|---|---|
| 9 | O resumo **diário existe sempre dentro do app, mas a notificação diária nasce desligada**. Você pediu retorno diário; a literatura recomenda não interromper todo dia | RN-813 · [feedback.md](feedback.md#o-pedido-e-a-literatura) |
| 10 | Resumo semanal entregue no **domingo às 20h**, configurável | RN-823 |
| 11 | O resumo diário **não usa IA**: é curto e formular, não justifica o custo | RN-815 |
| 12 | O app **sugere** marcar como fora do padrão quando o valor é o dobro da mediana da categoria em 90 dias | RN-814 |
| 13 | Comparação com o mês anterior só mostra diferença de **R$ 30 e 15%** ou mais, no máximo cinco itens | RN-834 |

### Primeiro uso e web

| # | Proposta | Onde |
|---|---|---|
| 14 | **O histórico da planilha não é importado**: o Cajui começa no mês corrente | Q1 |
| 15 | Parcelamento de cartão **anterior ao app** é cadastrado à mão, apontando para o cartão | Q2 |
| 16 | Na primeira fatura, informar uma vez o **"valor anterior ao Cajui"**, que explica a diferença sem virar despesa | Q3 |
| 17 | **A web não corrige categoria** na primeira versão: mostra o lançamento e indica o celular | Q7 |
| 18 | O app volta a pedir biometria depois de **2 minutos** em segundo plano, e esconde o conteúdo na miniatura do seletor de apps | RNF-SEC-19, RNF-SEC-20 |

As questões Q1 a Q10, com o contexto de cada uma, estão em [personas-and-journeys.md](personas-and-journeys.md#questões-abertas).

## O que fica para as próximas fases

| Assunto | Fase | Referência |
|---|---|---|
| Catálogo de erros definitivo, a partir dos códigos provisórios — **feito**: [error-catalog.md](error-catalog.md) | 3 | [use-cases.md](use-cases.md#códigos-de-erro-provisórios) |
| Desenho de cada tela e de cada estado | 3 | [use-cases.md](use-cases.md#telas-e-seus-estados) |
| Falta do mês em vermelho (padrão de mercado) ou em "barro": as duas versões lado a lado | 3 | D-UX-02 |
| Correção dos quatro furos de contraste da paleta | 3 | BL-016 |
| Autenticação do modo consulta na web | 4 | BL-011 |
| Formato do log cifrado e ordem de gravação | 4 | BL-015 |
| Todo número marcado "confirma no spike" | 4 | BL-002, BL-004, BL-019, BL-021 |
