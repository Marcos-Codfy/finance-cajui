# Casos de uso — dívidas

Formato e convenções em [use-cases.md](../use-cases.md). Regras em [debts.md](../rules/debts.md).

A tela de dívidas nunca é a tela de entrada, e o total nunca é o número em destaque (RN-540). Cada dívida mostra o já pago ao lado do que falta.

## UC-DEBT-01 — Cadastrar uma dívida

**Plataforma:** Android · **Grava:** `DebtRegistered` · **Regras:** RN-501, RN-502, RN-504

**Erros:** `E-DEBT-01` parcelas pagas maior que o total.

**Aceite:**
- Dado empréstimo de 12 parcelas de R$ 212 com 4 pagas, quando cadastrado, então entra R$ 212 no plano de cada mês até a última, e a tela mostra "Faltam 8 parcelas · R$ 1.696 · já pagos R$ 848".
- Dado uma dívida `informal` sem juros nem data certa, quando cadastrada com parcela e total, então funciona como as outras.

## UC-DEBT-02 — Pagar uma parcela

**Plataforma:** Android · **Gatilho:** lembrete, lista de dívidas ou captura · **Grava:** `EntryRecorded` ligado à dívida · **Regras:** RN-520, RN-521, RN-523, RN-524

**Aceite:**
- Dado a parcela 5 de 12 do empréstimo, quando paga em 15/09, então passam a constar 5 pagas e "Faltam 7 parcelas · R$ 1.484 · já pagos R$ 1.060. No ritmo atual, quita em abril de 2027."
- Dado a parcela paga com R$ 8,40 de multa, quando lançada, então são dois lançamentos: R$ 212,00 na dívida e R$ 8,40 em "juros e tarifas".
- Dado a parcela 3 da geladeira, que é `cardInstallment`, quando setembro corre, então ela conta no plano e aparece na fatura **sem** gerar lançamento novo (RN-521).
- Dado a parcela do dia 15 sem lançamento em 17/09, quando a lista abre, então aparece "em aberto desde 15/09", sem estimativa de multa.

## UC-DEBT-03 — Amortizar

**Plataforma:** Android · **Grava:** `EntryRecorded` marcado como amortização e `DebtChanged` · **Regras:** RN-522

**Fluxo:** 1. Valor extra pago. 2. O app pergunta o que o credor aplicou: reduzir o prazo ou reduzir a parcela. 3. O calendário da dívida é refeito.

**Aceite:**
- Dado amortização de R$ 424 reduzindo prazo, quando registrada, então a dívida termina duas parcelas antes e a previsão passa de abril para fevereiro de 2027.

## UC-DEBT-04 — Informar o valor para quitar hoje

**Plataforma:** Android · **Grava:** `DebtPayoffQuoteInformed` · **Regras:** RN-510, RN-511, RN-512

**Aceite:**
- Dado saldo nominal de R$ 1.484 e o credor informando R$ 1.310 para quitar, quando registrado em 12/09, então a tela mostra os dois: "Faltam 7 parcelas · R$ 1.484" e "Para quitar hoje: R$ 1.310,00 (informado em 12/09)".
- Dado o valor informado há 47 dias, quando a tela abre, então aparece "informado há 47 dias — pode ter mudado".
- Dado nenhuma taxa informada, quando a tela abre, então o app **não** exibe cálculo próprio de juros.

## UC-DEBT-05 — Quitar

**Plataforma:** Android · **Grava:** `DebtPaidOff` · **Regras:** RN-530, RN-532

**Fluxo:** 1. A última parcela é paga, ou o usuário registra a quitação antecipada pelo valor negociado. 2. O app marca o momento: ícone-herói, som de conquista se o som estiver ligado, uma frase sóbria.

**Aceite:**
- Dado a 12ª de 12 parcelas paga, quando lançada, então a dívida aparece como quitada, com o marco visível, e sai do plano a partir do mês seguinte.
- Dado a quitação, quando o texto aparece, então é factual: "Empréstimo quitado. Foram 12 parcelas; a partir de maio, R$ 212 a menos no mês." — sem exclamação em série.
- Dado a dívida quitada, quando o histórico é consultado, então ela continua lá.
- Dado o modo de movimento reduzido, quando a quitação acontece, então o marco aparece parado, no quadro final.
