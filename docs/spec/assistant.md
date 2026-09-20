# Conversa com IA

A conversa existe para que nenhum número do Cajui fique sem explicação: o usuário pergunta sobre as finanças reais do domicílio e recebe uma resposta que mostra de onde veio cada conta. As regras estão em [rules/assistant-and-privacy.md](rules/assistant-and-privacy.md) (RN-901 a RN-996); as conversas de exemplo, em [assistant-conversations.md](assistant-conversations.md). Termos em [glossary.md](glossary.md); tom em [voice-and-tone.md](../brand/voice-and-tone.md).

## Quem faz o quê

| Parte | Faz | Nunca faz |
|---|---|---|
| **IA (DeepSeek)** | Entende a pergunta, escolhe uma consulta ou simulação do catálogo, redige a resposta no tom da marca | Conta (RN-602), consulta livre (RN-921), gravação (RN-904), recomendação de produto financeiro (RN-902) |
| **Backend** | Monta o contexto, executa consultas e simulações com o domínio puro, redige dados pessoais, valida a saída, controla tokens, guarda a conversa | Enviar log, comprovante, dado pessoal ou identificador de aparelho (RN-914) |
| **App** | Envia a mensagem, mostra a resposta validada, abre a tela da ação sugerida | Falar com a DeepSeek (RN-907); mandar número ou contexto para o chat (RN-915) |
| **Usuário** | Pergunta e decide. Toda mudança passa por uma tela própria, com confirmação (RN-903) | — |

## O caminho de uma mensagem

1. O app envia o texto (até 1.000 caracteres) e o identificador da conversa. Na web, é a única rota que não é de leitura (RN-906).
2. O backend autentica, aplica o limite de requisições, normaliza e redige a mensagem (RN-952, RN-984) e confere o orçamento de tokens **antes** de qualquer chamada (RN-962).
3. O backend monta o contexto (RN-910 a RN-919) e o envio em ordem estável, para o cache de prefixo (RN-916): instruções e catálogos → meses fechados → mês aberto → janela da conversa → mensagem nova. Tudo o que é dado vai delimitado, em mensagem separada das instruções (RN-950).
4. A chamada passa pela fila com nova tentativa e espera exponencial (RN-970).
5. A IA devolve uma de duas coisas: **um pedido** de consulta ou simulação do catálogo, ou **a resposta final** no esquema fechado (RN-942).
6. Pedido: o backend valida os parâmetros, executa a função determinística e devolve o resultado como dado delimitado; volta ao passo 4. No máximo 3 rodadas por mensagem (RN-924).
7. Resposta final: o validador confere esquema, números com origem (RN-943), tom (RN-944), escopo (RN-902) e ações sugeridas. Reprovou: uma nova tentativa; reprovou de novo: resposta de formato fixo (RN-945).
8. Cada chamada gera um `AiUsageRecorded` (RN-965). A conversa é guardada fora do log (RN-956). O app recebe texto, origens, ações sugeridas e consumo — só então a resposta aparece, inteira (RN-946).

O mecanismo do passo 5 — chamada de função do provedor ou saída em JSON — é decisão da Fase 4. O requisito é a lista fechada e a validação por esquema.

## Desenho do contexto

Agregados pequenos, de tamanho que não cresce com o número de lançamentos (RN-910). Valores em centavos inteiros (RN-101); cada moeda em campo próprio (RN-917); todo número com a sua natureza (RN-918).

| Seção | Conteúdo | Natureza | Muda quando |
|---|---|---|---|
| `asOf` · `currentWeek` | Hoje; semana corrente com limite, gasto, resta e os componentes da conta (RN-641, RN-642) | fato | Lançamento variável em dinheiro |
| `month.income` | Renda em dinheiro (RN-610); vale disponível, gasto e saldo (RN-611, RN-120) | fato ou plano (RN-603) | Recebimento; compra no vale |
| `month.blocks` · `month.fixed[]` | Planejado e contado por bloco; cada fixo com nome, valor, dia e situação | plano e fato | Lançamento |
| `month.variables[]` | Faixa, pior caso em dinheiro (RN-425) e gasto por moeda, por categoria | plano e fato | Lançamento; mudança de faixa |
| `month.weeks[]` | Limite e gasto das semanas já passadas | fato | Lançamento tardio (RN-646) |
| `month.indicators` | Resultado planejado e projetado, comprometimento total e por grupo, custo por dia, ajuste necessário e folga (RN-620 a RN-662) | plano e projeção | Lançamento |
| `debts[]` | Rótulo, tipo, parcela, pagas e total, saldo nominal, taxa informada ou não, valor para quitar e sua data (RN-511), previsão de quitação | fato e projeção | Pagamento de parcela |
| `cards[]` | Rótulo, reserva da fatura (RN-320), vencimento e total parcial da próxima fatura | fato | Compra no cartão; liquidação |
| `exceptional` | Contagem, soma e média mensal de fora do padrão no ano (RN-241) | fato | Marcação |
| `closedMonths[]` | Os 3 últimos fechamentos: renda, contado por bloco, resultado realizado (RN-623) | fato | Fechamento ou revisão |

**O que nunca entra** (RN-912, RN-914): lançamento individual, estabelecimento, descrição, evento ou seu identificador, comprovante, texto extraído, dado pessoal, `deviceId`, token, IP. Detalhe só chega por consulta do catálogo, redigido e com teto.

### Exemplo de contexto

Setembro de 2026, com os números do [exemplo completo](rules/indicators.md#exemplo-completo), visto na manhã de segunda-feira, 21/09. A divisão do gasto por categoria, o cartão e agosto são ilustrativos — o exemplo de origem fixa os totais do plano e de cada semana. `month.fixed[]` e dois meses fechados foram omitidos por espaço.

```json
{
  "schema": "assistant-context/1",
  "asOf": "2026-09-21",
  "currentWeek": {
    "start": "2026-09-21", "end": "2026-09-27", "kind": "fact",
    "limitCents": 24500, "spentCents": 0, "remainingCents": 24500,
    "calc": { "variableLeftCents": 35000, "daysOfWeekInMonth": 7, "daysLeftInMonth": 10 }
  },
  "month": {
    "id": "2026-09", "status": "open", "days": 30,
    "income": {
      "cash": { "kind": "fact", "cents": 320000 },
      "mealVoucher": { "kind": "fact", "availableCents": 65000, "spentCents": 42000, "balanceCents": 23000 }
    },
    "blocks": {
      "fixed": { "plannedCents": 130000, "countedCents": 130000 },
      "debt": { "plannedCents": 36200, "countedCents": 36200 },
      "variable": { "worstCaseCashCents": 98000, "spentCashCents": 63000 }
    },
    "variables": [
      { "category": "mercado", "minCents": 50000, "maxCents": 80000, "voucherEligible": true,
        "worstCaseCashCents": 15000, "spentCashCents": 0, "spentVoucherCents": 42000 },
      { "category": "transporte", "minCents": 18000, "maxCents": 26000, "spentCashCents": 19000 },
      { "category": "lazer", "minCents": 10000, "maxCents": 25000, "spentCashCents": 19000 },
      { "category": "farmácia", "minCents": 5000, "maxCents": 15000, "spentCashCents": 11000 },
      { "category": "luz", "minCents": 11000, "maxCents": 17000, "spentCashCents": 14000 }
    ],
    "weeks": [
      { "start": "2026-09-01", "limitCents": 19600, "spentCents": 17000 },
      { "start": "2026-09-07", "limitCents": 23625, "spentCents": 26000 },
      { "start": "2026-09-14", "limitCents": 22647, "spentCents": 20000 }
    ],
    "indicators": {
      "plannedResult": { "kind": "plan", "type": "surplus", "cents": 55800 },
      "projectedResult": { "kind": "projection", "type": "surplus", "cents": 55800 },
      "commitmentPct": { "total": 52, "housing": 40, "transport": 8, "subscriptions": 6, "debts": 11 },
      "dailyCostPlannedCents": { "cash": 8807, "mealVoucher": 2167 },
      "requiredAdjustmentCents": 0
    }
  },
  "debts": [
    { "ref": "debt_1", "label": "Empréstimo Banco X", "type": "loan", "installmentCents": 21200,
      "paid": 5, "total": 12, "nominalBalanceCents": 148400, "rateInformed": false,
      "payoffForecast": { "kind": "projection", "month": "2027-04" } },
    { "ref": "debt_2", "label": "Geladeira", "type": "cardInstallment", "installmentCents": 15000,
      "paid": 3, "total": 10, "nominalBalanceCents": 105000,
      "payoffForecast": { "kind": "projection", "month": "2027-04" } }
  ],
  "cards": [
    { "ref": "card_1", "label": "Cartão final 4821", "statementReserveCents": 31000,
      "nextStatement": { "dueOn": "2026-10-05", "totalSoFarCents": 46000 } }
  ],
  "exceptional": { "year": 2026, "count": 4, "sumCents": 131000, "monthlyAvgCents": 14600 },
  "closedMonths": [
    { "id": "2026-08", "kind": "fact", "incomeCashCents": 320000,
      "countedCents": { "fixed": 130000, "debt": 36200, "variableCash": 89400 },
      "result": { "type": "surplus", "cents": 64400 } }
  ]
}
```

Conferência: 980,00 − 170,00 − 260,00 − 200,00 = 350,00 restantes; 350,00 × 7 ÷ 10 = limite de 245,00 (RN-641). Os gastos por categoria somam 630,00 e nenhum passa do máximo, então o resultado projetado segue igual ao planejado, 558,00 (RN-621). Agosto: 3.200 − 1.300 − 362 − 894 = 644.

## Catálogo de consultas

Lista fechada (RN-920 a RN-925). Só leitura; todo resultado vem com `kind`, período, teto de 20 linhas e de 12 meses, e o que passa do teto agregado em contagem e soma.

| Consulta | Parâmetros | Devolve |
|---|---|---|
| `month_summary` | mês | A seção `month` de um mês aberto ou fechado, até 12 meses atrás |
| `month_compare` | mês A, mês B | Diferença por bloco e por grupo, por moeda, já calculada |
| `indicator_breakdown` | indicador, mês ou semana | As parcelas da conta de um indicador (RN-620 a RN-662), na ordem da fórmula |
| `entries_top` | mês; bloco, grupo ou categoria | Os maiores lançamentos do recorte (campos da RN-923) e "outros N somam R$ X" |
| `entries_by_week` | início da semana | Limite, gasto e diferença da semana; os lançamentos que contam no limite (RN-643) |
| `category_history` | categoria, até 12 meses | Gasto por mês e por moeda, com a faixa vigente em cada mês |
| `card_statement` | cartão, ciclo | Total, vencimento, composição por bloco e categoria (RN-331), reserva, valor ainda não identificado (RN-332) |
| `debt_detail` | dívida | Calendário de parcelas, pagas e a pagar, saldo nominal, valor para quitar e há quantos dias foi informado (RN-512) |
| `voucher_statement` | mês | Créditos, gasto por categoria, ajustes e saldo do vale (RN-120) |
| `exceptional_summary` | ano | Lançamentos fora do padrão, soma e média mensal (RN-241) |
| `adjustment_options` | mês | Ajuste necessário, folga ajustável e os ajustes possíveis, do maior para o menor (RN-660 a RN-662) |

## Catálogo de simulações

Lista fechada (RN-930 a RN-937). Função pura do domínio; nada é gravado; todo resultado vem com entradas, base, premissas e `kind: projection`.

| Simulação | Parâmetros | Devolve | Premissas que a resposta declara |
|---|---|---|---|
| `debt_extra_payment` | dívida, valor extra por mês, mês de início | Novo mês de quitação, meses a menos, pagamentos e valor do último | Extra repetido todo mês; o credor reduz o prazo (RN-522); saldo nominal ou taxa informada (RN-533) |
| `debt_lump_sum` | dívida, valor único, mês | Parcelas a menos e novo mês de quitação | As mesmas |
| `variable_to_debt` | categoria, valor do ajuste, dívida | Se o ajuste cabe na folga da categoria (RN-661), o novo máximo e o resultado de `debt_extra_payment` com o mesmo valor | Ajuste repetido todo mês; aviso se passar do mínimo da faixa (RN-936) |
| `plan_change` | fonte de renda, fixo ou máximo de um variável; novo valor; mês de início | Novo resultado planejado, comprometimento total e por grupo, custo por dia e limite semanal | O resto do plano não muda |
| `new_installment_purchase` | valor, parcelas, cartão, data da compra | Parcela, meses em que conta (RN-311), total comprometido e comprometimento com dívidas mês a mês | Sem juros, salvo informados (RN-314); meses futuros só com o que já está comprometido (RN-935) |

A pergunta do requisito original — "se eu cortar X, em quanto tempo quito Y" — é `variable_to_debt`. Comparar cenários é repetir a simulação até 3 vezes (RN-937). A fórmula de amortização com taxa informada pertence às RN-5xx; enquanto ela não existir, a simulação roda só sobre o saldo nominal e diz isso.

## Ações sugeridas

Lista fechada (RN-903). Cada uma é um botão de verdade depois do texto; abre a tela já preenchida e nada grava sem confirmação. Na web, vira frase (RN-905).

| Ação | Botão | Abre |
|---|---|---|
| `open_debt` | Ver a dívida | A dívida citada |
| `inform_payoff_quote` | Informar o valor | O campo "para quitar hoje" da dívida (RN-511) |
| `register_amortization` | Lançar pagamento extra | Lançamento de amortização preenchido (RN-522) |
| `adjust_variable_range` | Ajustar *categoria* | Edição da faixa, com mês de início (RN-427) |
| `adjust_month_plan` | Ver os ajustes | Os ajustes possíveis do mês (RN-662, RN-663) |
| `open_entries` | Ver os lançamentos | A lista do recorte consultado |

## Estados da tela

Todo texto segue a fórmula do guia de voz: o que aconteceu, o que significa, o que dá para fazer. Avisos ficam na tela até serem dispensados e não movem o foco (D-APG-06).

| Estado | Quando | O que a tela diz | O que segue funcionando |
|---|---|---|---|
| Primeira vez | Sem conversa | "Pergunte sobre os seus números. Eu mostro de onde cada um veio, simulo cenários e comparo. Não recomendo investimento." Atalhos: "Quanto resta na semana?" · "Por que o mês sobra ou falta?" · "Simular pagamento extra" | Tudo |
| Respondendo | Do envio até a resposta validada | "Cajui está respondendo…", trocado pelo que está sendo feito: "Buscando os lançamentos de 07 a 13/09…", "Calculando a simulação…". Botão "Parar". O campo segue editável; enviar espera | Tudo |
| Demora | Nova tentativa em curso (RN-970) | "A IA está demorando. Estou tentando de novo." | Tudo |
| IA fora do ar | RN-972 | "Não consegui falar com a IA agora. Seus números e o resto do app seguem funcionando; só a redação das respostas está em pausa. Sua pergunta ficou no campo." Botões: "Tentar de novo" · "Ver os números" | Painel, lançamentos, relatórios, atalhos sem IA (RN-971) |
| 80% do mês | RN-963, uma vez | Faixa dispensável: "A IA já usou 80% do limite do mês: 400 mil de 500 mil tokens. Nada muda por enquanto." Botão: "Ver o uso" | Tudo |
| Limite do mês atingido | RN-964 | "O uso da IA chegou ao limite de setembro: 500 mil de 500 mil tokens. A conversa volta no dia 1º — ou agora, se você aumentar o limite. Os comprovantes seguem sendo classificados pelas regras locais." Botões: "Mudar o limite" · "Ver os números" | O mesmo de "IA fora do ar" |
| Sem rede | RN-973 | "Sem conexão agora. A conversa precisa do servidor para buscar seus números. O que você escreveu fica no campo; envie quando a rede voltar. Lançamentos continuam sendo salvos no aparelho." | Lançar; ler as mensagens já carregadas |
| IA desligada | RN-983 | "A IA está desligada nas configurações, então nada sai para a DeepSeek. Os números continuam aqui, pelos atalhos." Botões: "Ver os números" · "Abrir configurações" | O mesmo de "IA fora do ar" |
| Resposta de formato fixo | RN-945 | "Não consegui redigir uma resposta confiável para essa pergunta. Os números que encontrei estão abaixo. Quer perguntar de outro jeito?" | Tudo |
| Modo consulta na web | Sempre, na web | Aviso fixo sob o título: "Modo consulta: aqui dá para conversar, consultar e simular. Mudanças no plano e nos lançamentos se fazem no app do celular." Sem botões de ação sugerida. "Enter envia · Shift+Enter quebra a linha" escrito junto ao campo | Tudo o que é leitura |

O rodapé da conversa mostra o consumo do mês ("IA em setembro: 38% · 190 mil de 500 mil tokens"), e o detalhe de cada resposta mostra o consumo dela (RN-966). Os números de tokens desta tabela são exemplos; o padrão sai do spike da Fase 4.

## Teclado e leitor de tela

Contrato de D-APG-16, critério de aceite do componente na Fase 3:

- A conversa é lista em ordem cronológica, não feed. Cada mensagem é um nó único que começa pelo autor: "Você:" ou "Cajui:".
- A resposta nova é anunciada **uma vez**, completa, como status educado. O estado de espera também é status. Texto parcial nunca é anunciado (RN-946).
- Depois de enviar, o foco fica no campo. Enter envia; Shift+Enter quebra a linha.
- Ação sugerida é botão real, com nome único na tela ("Ajustar lazer", não "Ajustar") (D-APG-18).
- "De onde vieram os números" é botão com estado expandido ou recolhido; o nome não muda ao abrir (D-APG-08).
- Cenários lado a lado são tabela estática, com a mesma informação em frase (D-APG-13, D-UX-16).
- Mensagens antigas vêm pelo botão "Carregar mensagens anteriores", nunca por rolagem infinita.
- Apagar conversa é diálogo de alerta com foco inicial em "Cancelar" (D-APG-05).
