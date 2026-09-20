# Casos de uso — lançamentos

Formato e convenções em [use-cases.md](../use-cases.md). Regras em [entries-and-payments.md](../rules/entries-and-payments.md) e [income-and-tenders.md](../rules/income-and-tenders.md).

## UC-ENTRY-01 — Lançar uma despesa à mão

**Plataforma:** Android · **Gatilho:** botão "Lançar" · **Grava:** `EntryRecorded` · **Regras:** RN-201 a RN-206, RN-250

**Fluxo:** 1. Valor. 2. O que foi (descrição). 3. Categoria — o bloco aparece ao lado, derivado dela. 4. Por onde foi pago. 5. Data, com "hoje" pré-selecionado. 6. A tela mostra o efeito: "resta na semana: R$ 153,37 → R$ 144,87". 7. Confirmar.

**Alternativas:** estabelecimento já conhecido por regra aprendida preenche a categoria (RN-750). Categoria sem faixa avisa que o valor conta além do plano e oferece criar a faixa (RN-424).

**Erros:** `E-ENTRY-02` data futura · `E-ENTRY-03` valor zero ou negativo.

**Aceite:**
- Dado limite da semana de R$ 226,47 com R$ 73,10 gastos, quando o usuário lança ônibus de R$ 8,50 no Pix, então o resta na semana passa a R$ 144,87.
- Dado a data de amanhã, quando o usuário confirma, então o lançamento é recusado com `E-ENTRY-02` e nada é gravado.
- Dado o aparelho sem rede, quando o usuário lança, então o lançamento aparece na lista, conta nos indicadores e sobe sozinho quando a rede volta, uma única vez (RN-781).

## UC-ENTRY-02 — Dividir o pagamento entre vale e dinheiro

**Plataforma:** Android · **Gatilho:** "Dividir pagamento" na tela de lançar ou de confirmação · **Grava:** `EntryRecorded` com duas linhas · **Regras:** RN-112, RN-122, RN-203, RN-204

**Fluxo:** 1. O usuário escolhe o vale para uma compra maior que o saldo. 2. O app propõe a divisão: o saldo todo no vale, o resto em outra forma. 3. O usuário ajusta e confirma.

**Erros:** `E-VOUCHER-01` linha no vale maior que o saldo · `E-VOUCHER-02` categoria não elegível · `E-ENTRY-01` soma das linhas diferente do valor.

**Aceite:**
- Dado saldo de vale de R$ 30,00, quando o usuário paga mercado de R$ 86,00 com o vale, então o app propõe R$ 30,00 no vale e R$ 56,00 em dinheiro; ao confirmar, o saldo do vale vai a R$ 0,00 e o resta na semana cai R$ 56,00.
- Dado a categoria "internet", quando o usuário escolhe o vale, então a linha é recusada com `E-VOUCHER-02`.
- Dado linhas de R$ 30,00 e R$ 50,00 para um valor de R$ 86,00, quando o usuário confirma, então é recusado com `E-ENTRY-01` e a tela mostra "faltam R$ 6,00".

## UC-ENTRY-03 — Corrigir um lançamento

**Plataforma:** Android · **Gatilho:** tocar num lançamento da lista · **Grava:** `EntryCorrected` · **Regras:** RN-208, RN-764

**Fluxo:** 1. O usuário altera qualquer campo. 2. Confirma. 3. Se mudou a categoria, o app oferece lembrar do estabelecimento.

**Aceite:**
- Dado um lançamento em "lazer", quando a categoria vira "transporte", então o log mantém o original e acrescenta a correção; a lista mostra "transporte" e o histórico do lançamento mostra as duas versões.
- Dado qualquer correção, quando feita, então custa no máximo dois toques a partir da lista (D-UX-07).
- Dado uma correção num mês fechado, quando confirmada, então gera revisão do fechamento (RN-441).

## UC-ENTRY-04 — Cancelar um lançamento

**Plataforma:** Android · **Grava:** `EntryCancelled` · **Regras:** RN-208

**Fluxo:** 1. "Cancelar lançamento". 2. O app pede confirmação, dizendo o efeito nos indicadores. 3. Oferece "Desfazer" logo depois.

**Aceite:**
- Dado um lançamento de R$ 46,90 lançado por engano, quando cancelado, então some das visões, os indicadores voltam ao valor anterior e o evento original continua no log.
- Dado um lançamento ligado a um comprovante, quando cancelado, então o comprovante permanece guardado.

## UC-ENTRY-05 — Registrar um estorno

**Plataforma:** Android · **Gatilho:** "Registrar estorno" no lançamento, ou comprovante de devolução compartilhado · **Grava:** `EntryReversed` · **Regras:** RN-209, RN-210, RN-211

**Erros:** `E-ENTRY-04` estorno maior que o que resta do lançamento.

**Aceite:**
- Dado uma compra de R$ 120,00 em agosto, quando o estorno integral é registrado em setembro, então agosto não muda e setembro tem −R$ 120,00 na categoria.
- Dado uma compra paga no vale, quando estornada, então o saldo do vale sobe pelo mesmo valor.
- Dado um estorno de R$ 80,00 já registrado numa compra de R$ 120,00, quando o usuário tenta outro de R$ 60,00, então é recusado com `E-ENTRY-04`.

## UC-ENTRY-06 — Marcar como fora do padrão

**Plataforma:** Android · **Grava:** `EntryRecorded` ou `EntryCorrected`, com `isExceptional` · **Regras:** RN-240, RN-241, RN-648, RN-814

**Fluxo:** 1. O usuário liga a chave, ou aceita a sugestão do app. 2. O app mostra o acumulado do ano e a média mensal.

**Aceite:**
- Dado o conserto de R$ 700,00 no dia 3, marcado fora do padrão, quando lançado, então o mês passa a mostrar "faltam R$ 142" no segundo nível do painel e o limite da semana continua R$ 196,00 (RN-648 ⚑ validar).
- Dado o mesmo conserto **sem** a marca, quando lançado, então ele conta no gasto da semana.
- Dado três gastos fora do padrão no ano somando R$ 610, quando o quarto, de R$ 700, é marcado, então o app mostra "4º gasto fora do padrão do ano; somam R$ 1.310".

## UC-ENTRY-07 — Registrar um recebimento

**Plataforma:** Android · **Gatilho:** "Registrar entrada", ou comprovante de recebimento compartilhado (RN-758) · **Grava:** `IncomeReceived` · **Regras:** RN-131, RN-132, RN-133, RN-845

**Fluxo:** 1. O usuário escolhe a fonte, ou "entrada avulsa". 2. Informa valor e data. 3. O app mostra o efeito no mês.

**Aceite:**
- Dado salário esperado de R$ 2.400, quando o recebimento de R$ 2.310 é registrado, então o mês passa a calcular com R$ 2.310 e a sobra planejada cai R$ 90.
- Dado uma entrada avulsa de R$ 150 em setembro, quando o plano de outubro é gerado, então ela não aparece.
- Dado o mês com falta de R$ 142, quando o salário é lançado, então o app aproveita o momento: "Salário lançado: R$ 2.400. Faltam R$ 142 para fechar setembro; separei os ajustes que cobrem isso."

## UC-ENTRY-08 — Ajustar o saldo do vale

**Plataforma:** Android · **Grava:** `VoucherBalanceAdjusted` · **Regras:** RN-123, RN-233

**Aceite:**
- Dado saldo calculado de R$ 170,00 e saldo real de R$ 162,10, quando o usuário informa o real com o motivo "taxa da operadora", então o saldo vai a R$ 162,10 e nenhum indicador de despesa ou renda muda.

## UC-ENTRY-09 — Lançar com data de mês já fechado

**Plataforma:** Android · **Grava:** `EntryRecorded` e `MonthCloseRevised` · **Regras:** RN-252, RN-441, RN-646

**Aceite:**
- Dado setembro fechado com sobra de R$ 598, quando em 03/10 o usuário lança um ônibus de R$ 42,00 com data de 28/09, então o app avisa "Setembro rev. 2: + R$ 42,00 em transporte, lançado em 03/10", a sobra passa a R$ 556, a revisão 1 fica preservada e outubro não muda.
