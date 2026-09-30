# RN-3xx — Cartão de crédito

Formato e convenções em [README.md](README.md). Termos em [glossary.md](../glossary.md).

> **Cartão de crédito não é despesa. É forma de pagamento.** A fatura é uma visão derivada, nunca uma linha de despesa. É o requisito mais importante do produto.

## O cartão

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-301 | Cartão de crédito é uma forma de pagamento. Não existe como categoria, como bloco nem como lançamento | O cadastro de categorias rejeita nomes que representem o cartão ou a fatura; a classificação automática nunca propõe um (RN-207) | prompt |
| RN-302 | Cada cartão tem nome, dia de fechamento, dia de vencimento e, opcionalmente, limite de crédito | "Cartão final 4821" · fecha dia 25 · vence dia 5 | modelagem |
| RN-303 | O **dia de fechamento é o primeiro dia do ciclo novo**: compra feita até a véspera entra na fatura que fecha; compra feita no dia de fechamento ou depois entra na seguinte | Fecha dia 25: compra em 24/09 entra na fatura que vence em 05/10; compra em 25/09 entra na que vence em 05/11 | modelagem ⚑ validar |
| RN-304 | Quando o vencimento cai antes do fechamento no calendário, ele pertence ao mês seguinte ao do fechamento | Fecha dia 25, vence dia 5: o ciclo fechado em 25/09 vence em 05/10 | modelagem |
| RN-305 | O **limite tomado** de um cartão é tudo o que foi comprado nele e ainda não foi pago: o que resta de cada fatura ainda não liquidada, mais as parcelas que ainda vão vencer — inclusive as de compra anterior ao app (RN-521), quando a dívida estiver ligada ao cartão —, menos o que foi estornado, caia o estorno na fatura que cair. É a conta que o banco faz: compra parcelada toma o limite pelo valor inteiro e o devolve parcela a parcela, conforme as faturas são pagas. Limite livre = limite − tomado, nunca menor que zero; fatura paga a mais não devolve limite às outras (RN-344). Sem limite informado (RN-302), nada disso aparece. É visão calculada: nada é gravado, e nada é despesa | Limite de R$ 5.000,00. Fogão em 6× de R$ 160,00 com a 1ª parcela paga (restam R$ 800,00) e mercado de R$ 800,00 à vista na fatura de outubro, em aberto: tomado R$ 1.600,00, livre R$ 3.400,00 | decisão 2026-09-29, por delegação |

## Em que mês a compra conta

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-310 | Compra **à vista** no cartão conta no mês da **data da compra** — não no mês da fatura — e reduz o limite da semana no mesmo instante em que é lançada | Mercado de R$ 186,40 no cartão em 12/09: setembro gasta R$ 186,40 de variável e o limite daquela semana cai R$ 186,40, embora o dinheiro só saia em 05/10 | decisão 2026-09-19 · D-UX-05 |
| RN-311 | Compra **parcelada** gera um parcelamento de N parcelas, rateadas pela RN-102. A parcela *k* conta no **mês em que vence** a fatura em que ela é cobrada; a primeira é cobrada na fatura do ciclo da compra | Fogão de R$ 960,00 em 6× comprado em 19/09, cartão que fecha dia 25 e vence dia 5: seis parcelas de R$ 160,00 contando de outubro a março. Setembro não muda | decisão 2026-09-19 |
| RN-312 | O parcelamento entra no orçamento como **compromisso do bloco de dívidas** (tipo `cardInstallment`, sem juros), guardando a categoria original da compra para análise. Não consome orçamento de variável nem limite semanal | O fogão aparece em "dívidas" com 6 parcelas de R$ 160 e não reduz o limite da semana da compra; nos relatórios por categoria continua sendo "casa" | modelagem ⚑ validar |
| RN-313 | Todo parcelamento exibe sempre o **total ainda comprometido**, ao lado da parcela | Geladeira comprada em julho, em setembro: "Parcela 3 de 10 · R$ 150,00 · ainda comprometido R$ 1.200,00" (da 3ª à 10ª) | decisão 2026-09-19 · D-UX-05 |
| RN-314 | Compra parcelada **com juros** registra o valor à vista como o valor do lançamento e a diferença para a soma das parcelas como custo de juros do parcelamento, exibido à parte | R$ 1.500 à vista, 10× de R$ 165: lançamento de R$ 1.500 e juros totais de R$ 150 | modelagem |

## A reserva da fatura

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-320 | Como a compra à vista conta no mês da compra e o dinheiro só sai no vencimento, o app mantém a **reserva da fatura**: a soma das linhas à vista no cartão já contadas e ainda não liquidadas | Em 30/09 há R$ 640 de compras à vista no cartão ainda não pagas: "Reservado para a fatura: R$ 640" | modelagem |
| RN-321 | A reserva da fatura não é despesa nova nem reduz a sobra: o valor já foi contado quando a compra entrou. Ela só informa quanto do dinheiro do mês já tem destino | Sobra de setembro R$ 558 **e** reserva de R$ 640 são números independentes | modelagem |

## A fatura

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-330 | A fatura de um cartão num ciclo é calculada: linhas à vista com data da compra no ciclo + parcelas cobradas no ciclo − estornos no ciclo + juros e tarifas do ciclo. Nunca é digitada nem armazenada como despesa | Apagar todos os lançamentos de um ciclo zera a fatura daquele ciclo | prompt |
| RN-331 | A fatura mostra total, vencimento e composição por bloco e por categoria | "R$ 1.240,00 · vence 05/10 · variáveis R$ 890 · fixos R$ 200 · parcelas R$ 150" | prompt |
| RN-332 | O usuário pode informar o total real da fatura do banco. A diferença aparece como "**R$ X ainda não identificados**" e abre a busca por lançamentos que faltam; o app **nunca** cria uma despesa de ajuste para fechar a conta | Fatura calculada R$ 1.180, fatura real R$ 1.240: "R$ 60 ainda não identificados nesta fatura" | modelagem |
| RN-333 | Anuidade, juros, multa e tarifa cobrados na fatura são lançamentos comuns, pagos com o próprio cartão, na categoria "juros e tarifas" (bloco dívidas) | Anuidade de R$ 25: lançamento de R$ 25 em "juros e tarifas", pago com o cartão | modelagem |

## Pagar a fatura

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-340 | Pagar a fatura é uma **liquidação**: registra data, valor e cartão. Não é lançamento, não entra em bloco nenhum e não muda indicador de despesa | Pagar R$ 1.240 em 05/10 não acrescenta R$ 1.240 às despesas de outubro | prompt |
| RN-341 | A liquidação reduz a reserva da fatura pelo valor das linhas à vista que ela quita | Reserva R$ 640 → R$ 0 depois da liquidação integral | modelagem |
| RN-342 | Liquidação **menor** que a fatura deixa um saldo em aberto. O app pergunta o que foi combinado com o banco e registra o saldo como uma dívida (`cardRevolving` para rotativo, `cardInstallment` para parcelamento de fatura), com os juros informados pelo usuário | Fatura R$ 1.240, pago R$ 400: dívida de R$ 840 com a taxa informada | modelagem |
| RN-343 | Comprovante compartilhado que seja um **pagamento de fatura** é proposto como liquidação, nunca como lançamento de despesa | PDF "Pagamento de fatura — R$ 1.240,00": o app abre a tela de liquidação com o cartão sugerido | prompt |
| RN-344 | Liquidação maior que a fatura calculada é aceita com aviso, e a diferença alimenta a busca da RN-332 | Pago R$ 1.240, calculado R$ 1.180: "R$ 60 pagos a mais que o identificado" | modelagem |

## O que a regra impede

Três erros de planilha que passam a ser impossíveis:

| Erro | Por que não acontece |
|---|---|
| Lançar a compra **e** a fatura, contando em dobro | A fatura não pode ser lançada (RN-301, RN-340) |
| Lançar só a fatura e perder as categorias | A fatura é derivada dos lançamentos (RN-330); sem eles, ela é zero |
| Ver o gasto só no mês seguinte | A compra à vista conta na data da compra (RN-310) |
