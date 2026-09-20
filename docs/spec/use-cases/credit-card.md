# Casos de uso — cartão de crédito

Formato e convenções em [use-cases.md](../use-cases.md). Regras em [credit-card.md](../rules/credit-card.md). Jornadas C e D em [journeys.md](../journeys.md).

> Cartão de crédito não é despesa: é forma de pagamento. Nenhum caso abaixo cria uma despesa chamada "fatura".

O cartão do exemplo: final 4821, fecha dia 25, vence dia 5.

## UC-CARD-01 — Compra à vista no cartão

**Plataforma:** Android · **Gatilho:** lançar ou confirmar captura com forma "cartão de crédito", uma parcela · **Grava:** `EntryRecorded` · **Regras:** RN-310, RN-320, RN-643

**Fluxo:** 1. O usuário lança a compra normalmente, escolhendo o cartão. 2. A tela mostra o efeito imediato no resta na semana e diz em que fatura a compra cai. 3. Confirmar.

**Aceite:**
- Dado mercado de R$ 186,40 no cartão em 12/09, quando lançado, então setembro conta R$ 186,40 de variável, o resta da semana de 07 a 13/09 cai R$ 186,40 **na hora**, e a compra aparece na fatura que vence em 05/10.
- Dado a mesma compra, quando lançada, então a reserva da fatura sobe R$ 186,40 e a sobra do mês **não** cai duas vezes (RN-321).
- Dado uma compra em 25/09, quando lançada, então conta em setembro, mas aparece na fatura que vence em 05/11.

## UC-CARD-02 — Compra parcelada no cartão

**Plataforma:** Android · **Grava:** `EntryRecorded` com `installmentPlan` e `DebtRegistered` do tipo `cardInstallment` · **Regras:** RN-311, RN-312, RN-313, RN-314, RN-503

**Fluxo:** 1. O usuário informa o número de parcelas (ou o app leu "6×" do comprovante). 2. A tela mostra a parcela, os meses em que ela conta e o total comprometido. 3. Confirmar.

**Alternativas:** compra no cartão sem indicação de parcelas na captura: a confirmação pergunta "À vista ou parcelado?" antes de assumir à vista. Com juros, o usuário informa o valor da parcela e o app mostra os juros totais à parte (RN-314).

**Aceite:**
- Dado fogão de R$ 960,00 em 6× comprado em 19/09, quando lançado, então são seis parcelas de R$ 160,00 contando de outubro a março, setembro não muda, o resta na semana **não** cai, e a tela mostra "ainda comprometido R$ 960,00".
- Dado R$ 100,00 em 3×, quando lançado, então as parcelas são R$ 33,34, R$ 33,33 e R$ 33,33 (RN-102).
- Dado o fogão lançado, quando a tela de dívidas abre, então mostra "Fogão: faltam 6 parcelas · R$ 960 · já pagos R$ 0. No ritmo atual, quita em março de 2027."
- Dado o plano de outubro, quando gerado, então as dívidas somam R$ 522,00 (212 + 150 + 160) e a sobra planejada é R$ 348,00.

## UC-CARD-03 — Ver a fatura

**Plataforma:** ambas · **Grava:** nada · **Regras:** RN-330, RN-331

**Fluxo:** 1. O usuário escolhe o cartão e o ciclo. 2. O app mostra total, vencimento e composição por bloco e por categoria, com a lista dos lançamentos.

**Aceite:**
- Dado um ciclo com R$ 890 de variáveis à vista, R$ 200 de fixos e a parcela de R$ 150 da geladeira, quando a fatura abre, então mostra "R$ 1.240,00 · vence 05/10 · variáveis R$ 890 · fixos R$ 200 · parcelas R$ 150".
- Dado todos os lançamentos de um ciclo cancelados, quando a fatura abre, então o total é R$ 0,00: a fatura não existe fora dos lançamentos.
- Dado a fatura aberta, quando o usuário procura um botão para "lançar fatura", então não existe.

## UC-CARD-04 — Informar o total real e achar o que falta

**Plataforma:** Android · **Grava:** `StatementTotalInformed` · **Regras:** RN-332, RN-344

**Fluxo:** 1. O usuário digita o total que o banco cobrou. 2. O app mostra a diferença como "ainda não identificados" e abre a busca por dia. 3. Cada lançamento encontrado reduz a diferença.

**Alternativas:** na primeira fatura depois de começar a usar o app, o usuário informa uma vez o "valor anterior ao Cajui" daquele ciclo, que explica a diferença sem virar despesa (Q3 ⚑ validar).

**Aceite:**
- Dado fatura calculada de R$ 1.180 e total real de R$ 1.240, quando informado, então aparece "R$ 60 ainda não identificados nesta fatura" e **nenhuma** despesa de ajuste é criada.
- Dado o usuário lança um café de R$ 60,00 daquele ciclo, quando salvo, então a diferença vai a R$ 0,00.

## UC-CARD-05 — Pagar a fatura

**Plataforma:** Android · **Gatilho:** "Registrar pagamento" na fatura, ou comprovante de pagamento de fatura compartilhado (UC-CAPT-07) · **Grava:** `StatementSettled` · **Regras:** RN-340, RN-341

**Fluxo:** 1. Data, valor pago, cartão e ciclo. 2. Confirmar.

**Aceite:**
- Dado fatura de R$ 1.240,00, quando o usuário registra o pagamento de R$ 1.240,00 em 05/10, então **nenhuma** despesa é acrescentada a outubro, a reserva da fatura cai pelo valor das compras à vista quitadas, e a fatura aparece como paga.
- Dado o fechamento de outubro, quando gerado, então os R$ 1.240,00 não aparecem em bloco nenhum.

## UC-CARD-06 — Pagar só parte da fatura

**Plataforma:** Android · **Grava:** `StatementSettled` e `DebtRegistered` · **Regras:** RN-342, RN-333

**Fluxo:** 1. O valor pago é menor que o total. 2. O app pergunta o que foi combinado com o banco: rotativo ou parcelamento da fatura. 3. O usuário informa a taxa ou o valor das parcelas. 4. O saldo vira uma dívida.

**Aceite:**
- Dado fatura de R$ 1.240 e pagamento de R$ 400, quando registrado como rotativo, então nasce uma dívida `cardRevolving` de R$ 840 com a taxa informada, e o texto não julga: "Ficaram R$ 840 para depois. Registrei como dívida do cartão, com os juros que você informou."
- Dado juros de R$ 96,00 cobrados na fatura seguinte, quando lançados, então entram como lançamento em "juros e tarifas", bloco dívidas, pagos com o próprio cartão.
