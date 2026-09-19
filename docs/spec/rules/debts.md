# RN-5xx — Dívidas

Formato e convenções em [README.md](README.md). Termos em [glossary.md](../glossary.md).

Dívida, aqui, é toda obrigação **com fim**: tem parcelas contadas e um dia em que acaba. O que não tem fim — aluguel, assinatura — é fixo.

## A dívida

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-501 | Uma dívida tem credor, tipo, valor da parcela, número total de parcelas, parcelas já pagas, dia de vencimento e data de início. Juros mensais e valor original são opcionais | "Empréstimo Banco X" · R$ 212,00 · 12 parcelas · 5 pagas · dia 15 | prompt |
| RN-502 | Tipos de dívida: `loan` (empréstimo), `financing` (financiamento), `cardInstallment` (parcelamento no cartão), `cardRevolving` (rotativo ou parcelamento de fatura) e `informal` (dinheiro devido a uma pessoa) | — | modelagem |
| RN-503 | O parcelamento de uma compra no cartão (RN-311) cria automaticamente uma dívida do tipo `cardInstallment`, sem juros, ligada ao lançamento de origem | A geladeira em 10× vira uma dívida de 10 parcelas de R$ 150 | modelagem ⚑ validar |
| RN-504 | A parcela do mês entra no plano como despesa do bloco de dívidas, em dinheiro | Setembro: R$ 212 + R$ 150 = R$ 362 em dívidas | prompt |

## Saldo devedor

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-510 | O **saldo devedor nominal** é a soma das parcelas que faltam. É o número padrão, porque não depende de dado que o usuário talvez não tenha | 7 parcelas de R$ 212 → R$ 1.484,00 | modelagem |
| RN-511 | O app não calcula tabela de juros por conta própria. Se o usuário informar o **valor para quitar hoje** obtido com o credor, ele é exibido à parte, com a data em que foi informado | "Para quitar hoje: R$ 1.310,00 (informado em 12/09)" | modelagem |
| RN-512 | Valor para quitar informado há mais de 30 dias é exibido como desatualizado | "informado há 47 dias — pode ter mudado" | modelagem |

## Pagar

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-520 | Pagar uma parcela é um lançamento do bloco de dívidas ligado à dívida; ele incrementa as parcelas pagas | Pagar a 6ª parcela: 6 de 12 pagas | modelagem |
| RN-521 | Parcela de `cardInstallment` não gera lançamento novo quando vence: o lançamento é a compra original. A parcela conta no plano do mês e é cobrada na fatura (RN-330) | A parcela 3 da geladeira aparece no plano de dezembro e na fatura que vence em dezembro, sem novo lançamento | modelagem |
| RN-522 | Pagamento **extra** é um lançamento marcado como amortização. O efeito — reduzir o prazo ou reduzir a parcela — é o que o credor aplicou, informado pelo usuário | Amortização de R$ 424 reduzindo prazo: 2 parcelas a menos no fim | modelagem |
| RN-523 | Multa e juros por atraso são lançamento à parte, na categoria "juros e tarifas", nunca somados ao valor da parcela | Parcela de R$ 212 paga com R$ 8,40 de multa: dois lançamentos | modelagem |
| RN-524 | Parcela vencida sem lançamento aparece como "em aberto", sem estimativa automática de multa | — | modelagem |

## Quitação e previsão

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-530 | A dívida é dada como **quitada** quando as parcelas pagas igualam o total, ou quando o usuário registra a quitação antecipada. A quitação é um evento próprio | Pagar a 12ª de 12: evento de quitação, marco visível no app | D-UX-14 |
| RN-531 | A **previsão de quitação** é o mês da última parcela no calendário atual. É sempre apresentada como projeção | "No ritmo atual, quita em abril de 2027" | modelagem |
| RN-532 | Dívida quitada sai do plano a partir do mês seguinte ao da última parcela e permanece no histórico | — | modelagem |
| RN-533 | Simulações ("e se eu pagar R$ 100 a mais por mês?") são calculadas pelo servidor, de forma determinística, sobre o saldo nominal ou sobre a taxa informada; o resultado diz qual dos dois foi usado | "Usei o saldo nominal, sem juros, porque a taxa não foi informada" | D-UX-23 |

## Como a dívida aparece

Estas três regras são de apresentação, mas ficam aqui porque protegem o propósito do produto.

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-540 | A tela de dívidas nunca é a tela de entrada do app, e o total das dívidas nunca é o número em destaque dela | O total aparece como soma no rodapé da lista | D-UX-14 |
| RN-541 | Cada dívida mostra primeiro o número — parcelas que faltam e valor — com o **já pago ao lado do que falta**; a barra de progresso é secundária e conta desde o início | "Faltam 7 parcelas · R$ 1.484 · já pagos R$ 1.060" | D-UX-14 · D-UX-15 |
| RN-542 | Nenhum texto sobre dívida atribui falha à pessoa | "Faltam 7 parcelas de R$ 212" — nunca "você ainda deve R$ 1.484!" | D-UX-22 |
