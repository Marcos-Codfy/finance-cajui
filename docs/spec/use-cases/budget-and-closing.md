# Casos de uso — orçamento e fechamento

Formato e convenções em [use-cases.md](../use-cases.md). Regras em [blocks-and-budget.md](../rules/blocks-and-budget.md) e [indicators.md](../rules/indicators.md). Jornadas F e G em [journeys.md](../journeys.md).

## UC-BUDG-01 — Ver o painel

**Plataforma:** ambas · **Gatilho:** abrir o app · **Grava:** nada · **Regras:** RN-670, RN-671, RN-642, RN-622, RN-630, RN-111, RN-402

**Fluxo:** 1. Primeiro nível: **resta na semana**, em frase ("Sobram R$ 106,47 até domingo."), com o limite e o gasto logo abaixo. 2. Segundo nível, na mesma tela e sem toque: sobra ou falta do mês, comprometimento, os três blocos com barra própria, e o vale em linha separada. 3. Terceiro: lançamentos de hoje, reserva da fatura, capturas para conferir.

**Aceite:**
- Dado sábado, 19/09, com R$ 120,00 gastos na semana de limite R$ 226,47, quando o painel abre, então o número principal é "Sobram R$ 106,47 até domingo."
- Dado o mês com falta de R$ 142, quando o painel abre, então o número principal **continua** sendo o resta na semana; "Faltam R$ 142 para fechar setembro" aparece no segundo nível, com sinal, rótulo e ícone — nunca só por cor — e ao lado de "Ver os ajustes".
- Dado qualquer estado, quando o painel é inspecionado, então não existe nenhum total que some dinheiro e vale.
- Dado a semana de 28 a 30/09, quando o painel abre, então o texto diz "até quarta, 30 de set.", não "até domingo" (RN-644, Q9).
- Dado o variável do mês já esgotado, quando o painel abre, então mostra "O variável do mês já passou R$ 40 do plano", sem alarme (RN-645).
- Dado a web, quando o painel abre, então mostra os mesmos números do celular e nenhum controle de lançar.
- Tempo de abertura e fluidez: RNF-PERF-01 e seguintes.

## UC-BUDG-02 — Ver e editar o plano do mês

**Plataforma:** Android edita; web só vê · **Grava:** `MonthPlanAdjusted`, `FixedExpenseChanged`, `VariableBudgetChanged` · **Regras:** RN-430 a RN-433, RN-412, RN-427

**Aceite:**
- Dado 1º de outubro, quando o app abre, então o plano de outubro já existe, com vale de R$ 600, mercado em dinheiro de R$ 200, dívidas de R$ 522 e "Outubro no plano: sobram R$ 348."
- Dado o aluguel alterado para R$ 1.180 a partir de janeiro, quando salvo, então dezembro e os fechamentos anteriores não mudam.
- Dado março do ano seguinte, quando aberto, então mostra só fixos vigentes e parcelas — nenhum variável projetado (RN-433).

## UC-BUDG-03 — Remanejar entre categorias ou blocos

**Plataforma:** Android · **Grava:** `BudgetReallocated` · **Regras:** RN-403

**Erros:** `E-BUDG-04` valor maior que a folga da origem.

**Aceite:**
- Dado lazer com folga de R$ 90 e transporte R$ 40 acima do máximo, quando o usuário move R$ 40 de lazer para transporte, então o evento registra origem, destino, valor e mês, e o fechamento lista o remanejamento.
- Dado qualquer bloco acima do plano, quando nenhum remanejamento foi feito, então nenhum outro bloco foi reduzido por conta própria.

## UC-BUDG-04 — Ver e aplicar os ajustes

**Plataforma:** Android aplica; web só vê · **Gatilho:** "Ver os ajustes", no painel ou num aviso · **Grava:** `MonthPlanAdjusted` · **Regras:** RN-660 a RN-663

**Fluxo:** 1. O app mostra quanto falta ajustar e a folga de cada variável, do maior para o menor. Nenhum vem marcado; nenhum é chamado de supérfluo. 2. O usuário escolhe quanto tirar de onde; um contador mostra o que ainda falta. 3. "Aplicar os ajustes".

**Erros:** `E-BUDG-03` ajuste abaixo do mínimo da faixa.

**Aceite:**
- Dado a falta de R$ 142 depois do conserto de R$ 700, quando a tela abre, então mostra: lazer até R$ 150 · mercado até R$ 150 · farmácia até R$ 100 · transporte até R$ 80 · luz até R$ 60, e "Dá para ajustar até R$ 540."
- Dado lazer −R$ 100 e transporte −R$ 42 escolhidos, quando aplicados, então o contador vai "R$ 142 → R$ 42 → R$ 0", o mês passa a "fecha no zero" e o limite das semanas seguintes é recalculado.
- Dado um conserto de R$ 1.200, quando a tela abre, então diz "Os variáveis cobrem R$ 540. Os R$ 102 restantes dependem de renda, de fixo ou de dívida.", com atalho para cada um (RN-662).
- Dado "Agora não", quando tocado, então o app aceita, não insiste e não repete o aviso (RN-846).

## UC-BUDG-05 — Fechar o mês

**Plataforma:** Android · **Gatilho:** aviso "pronto para fechar", ou o menu do mês · **Grava:** `MonthClosed` · **Regras:** RN-440, RN-442, RN-830 a RN-837, RN-422

**Fluxo:** 1. O app lista o que está em aberto: fixo sem lançamento, renda sem recebimento, captura pendente, valor não identificado em fatura. 2. Mostra "Como foi o mês" e "Como fica adiante" ([feedback.md](../feedback.md#mensal)). 3. "Fechar setembro".

**Erros:** `E-BUDG-02` mês ainda não terminado: "Setembro ainda não acabou. Dá para fechar a partir de 1º de outubro."

**Aceite:**
- Dado setembro com fixos de 1.300, dívidas de 362 e variável de 940, quando fechado, então o resultado é "R$ 598,00 de sobra, R$ 40,00 acima do plano", e o texto começa pelo que foi cumprido.
- Dado o fechamento gravado, quando uma faixa é alterada em outubro, então o fechamento de setembro não muda.
- Dado a sobra de R$ 598, quando outubro é calculado, então ela **não** entra como orçamento extra (RN-422).
- Dado setembro com falta de R$ 102, quando fechado, então a estrutura é a mesma, a falta aparece como valor a recompor, e nada é descontado de outubro (RN-443 ⚑ validar).
- Dado o mês nunca fechado, quando outubro corre, então tudo funciona igual e o aviso de fechamento não se repete.

## UC-BUDG-06 — Ver a revisão de um fechamento

**Plataforma:** ambas · **Grava:** nada (a revisão nasce em UC-ENTRY-09) · **Regras:** RN-441

**Aceite:**
- Dado setembro na revisão 2, quando aberto, então mostra a revisão atual, a diferença ("+ R$ 42,00 em transporte, lançado em 03/10") e acesso à revisão 1, intacta.

## UC-BUDG-07 — Dar um fixo como pago

**Plataforma:** Android · **Grava:** `EntryRecorded` ligado à ocorrência · **Regras:** RN-411, RN-414, RN-749

**Fluxo:** 1. Pelo lembrete, pela lista de fixos ou por captura que casou com a ocorrência. 2. O app propõe o valor esperado; o usuário confirma o que pagou.

**Aceite:**
- Dado internet esperada de R$ 100, quando o usuário confirma R$ 104,90, então o mês passa a calcular com R$ 104,90.
- Dado o aluguel do dia 10 sem lançamento em 12/09, quando a lista abre, então aparece "em aberto desde 10/09", sem multa estimada e sem bronca.
- Dado um comprovante de R$ 1.100 para a imobiliária, quando capturado, então a confirmação pergunta "É o aluguel de setembro?" e, aceito, liga o lançamento à ocorrência.
