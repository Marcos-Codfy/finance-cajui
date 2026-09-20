# Casos de uso — configuração inicial

Formato e convenções em [use-cases.md](../use-cases.md). Jornada correspondente: [A — primeiro uso](../journeys.md). Meta: sair da planilha e ver o primeiro painel em **menos de 10 minutos**.

O Cajui começa no mês corrente: o histórico da planilha não é importado (Q1 ⚑ validar). Todo passo pode ser pulado e retomado; o painel funciona com o que houver.

## UC-SETUP-01 — Boas-vindas e preferências

**Plataforma:** Android · **Gatilho:** primeira abertura depois do pareamento (UC-SET-04) · **Grava:** `HouseholdConfigured` · **Regras:** convenções de fuso em [rules/README.md](../rules/README.md)

**Fluxo:** 1. O app explica em três telas curtas o que faz: lê comprovante compartilhado, separa o que foi comprado de por onde foi pago, mostra quanto cabe na semana. 2. Oferece ligar os sons, com prévia audível. 3. Confirma o fuso do domicílio, sugerido pelo aparelho.

**Alternativas:** pular os sons mantém desligado (padrão).

**Aceite:**
- Dado uma instalação nova, quando a configuração termina sem tocar em nada de som, então o som está desligado e o controle está visível nas configurações.
- Dado o fuso `America/Araguaina`, quando um lançamento é feito às 23h50 do dia 30/09, então ele conta em setembro.

## UC-SETUP-02 — Cadastrar as rendas e o vale

**Plataforma:** Android · **Grava:** `IncomeSourceDefined` (uma por fonte) e, se houver saldo, `VoucherBalanceAdjusted` · **Regras:** RN-130, RN-110, RN-123

**Fluxo:** 1. O usuário informa cada fonte: nome, valor esperado, dia esperado. 2. Marca qual é o vale. 3. Informa o saldo atual do cartão do vale; o app o registra como ajuste com motivo "saldo inicial".

**Aceite:**
- Dado salário de R$ 2.400 no dia 5, segunda renda de R$ 800 no dia 20 e vale de R$ 600 no dia 1, quando o cadastro termina, então a renda em dinheiro do mês é R$ 3.200 e o crédito do vale é R$ 600 — dois números, nunca R$ 3.800.
- Dado saldo inicial de vale de R$ 50, quando o mês é calculado, então o vale disponível é R$ 650 (RN-611).

## UC-SETUP-03 — Revisar categorias

**Plataforma:** Android · **Grava:** `CategoryDefined`, `CategoryChanged` · **Regras:** RN-202, RN-113, RN-301

**Fluxo:** 1. O app traz uma lista inicial de categorias, cada uma com bloco, grupo e elegibilidade ao vale. 2. O usuário renomeia, cria ou desativa. 3. Marca quais aceitam o vale.

**Erros:** `E-CARD-02` ao tentar criar uma categoria que represente cartão ou fatura: "Cartão é por onde você paga, não o que você comprou. O que foi comprado entra na categoria; o cartão entra em 'por onde foi pago'."

**Aceite:**
- Dado o nome "Fatura do cartão", quando o usuário tenta criar a categoria, então ela é recusada com `E-CARD-02`.
- Dado "restaurante" marcado como elegível, quando um almoço é pago no vale, então a linha é aceita (RN-112).

## UC-SETUP-04 — Cadastrar formas de pagamento e cartões

**Plataforma:** Android · **Grava:** `PaymentMethodDefined` · **Regras:** RN-205, RN-302, RN-303, RN-304

**Fluxo:** 1. Dinheiro vivo, Pix, débito, boleto e vale já existem. 2. Para cada cartão de crédito: apelido, final, dia de fechamento, dia de vencimento e, se quiser, limite.

**Erros:** `E-CARD-01` para dia fora de 1 a 31.

**Aceite:**
- Dado um cartão que fecha dia 25 e vence dia 5, quando uma compra é feita em 24/09, então ela aparece na fatura que vence em 05/10; feita em 25/09, na que vence em 05/11 (RN-303 ⚑ validar).

## UC-SETUP-05 — Cadastrar os fixos

**Plataforma:** Android · **Grava:** `FixedExpenseDefined` · **Regras:** RN-410, RN-413

**Fluxo:** 1. Nome, valor, dia de vencimento, categoria e forma habitual. 2. Se o usuário disser que o valor muda todo mês, o app sugere cadastrar como variável com faixa.

**Aceite:**
- Dado aluguel 1.100, internet 100, streaming 40 e celular 60, quando o plano de setembro é gerado, então os fixos somam R$ 1.300,00.
- Dado "conta de luz" informada como fixo com valor que muda, quando o usuário confirma que muda, então o app oferece a faixa e não cria o fixo (RN-413).

## UC-SETUP-06 — Definir as faixas dos variáveis

**Plataforma:** Android · **Grava:** `VariableBudgetDefined` · **Regras:** RN-420, RN-421, RN-425

**Fluxo:** 1. Para cada categoria variável, mínimo e máximo. 2. O app mostra, ao vivo, o efeito no resultado planejado, usando sempre o máximo.

**Erros:** `E-BUDG-01` para mínimo maior que o máximo.

**Aceite:**
- Dado mercado 500–800 elegível ao vale, com vale disponível de R$ 650, quando o plano é calculado, então a parte do mercado em dinheiro é R$ 150,00.
- Dado as cinco faixas do exemplo, quando o plano é calculado, então o variável em dinheiro é R$ 980,00 e a sobra planejada é R$ 558,00.

## UC-SETUP-07 — Cadastrar dívidas e parcelamentos em andamento

**Plataforma:** Android · **Grava:** `DebtRegistered` · **Regras:** RN-501, RN-502, RN-503, RN-510

**Fluxo:** 1. Credor, tipo, valor da parcela, total de parcelas, quantas já foram pagas, dia de vencimento. 2. Parcelamento de cartão anterior ao app é cadastrado como `cardInstallment`, apontando para o cartão, sem lançamento de origem (Q2 ⚑ validar).

**Erros:** `E-DEBT-01` para parcelas pagas maior que o total.

**Aceite:**
- Dado empréstimo de 12 parcelas de R$ 212 com 4 pagas e geladeira de 10 de R$ 150 com 2 pagas, quando setembro é calculado, então as dívidas do mês são R$ 362,00 e o comprometimento total é 52%.
- Dado a geladeira apontando para o cartão final 4821, quando a fatura do ciclo é calculada, então a parcela de R$ 150 aparece nela (RN-330).

## UC-SETUP-08 — Conferir o primeiro painel

**Plataforma:** Android · **Grava:** nada · **Regras:** RN-620, RN-630, RN-641, RN-670

**Fluxo:** 1. O app mostra o painel já calculado. 2. O usuário confere com a planilha. 3. "Ver a conta" abre cada número com suas parcelas.

**Aceite:**
- Dado o cadastro completo do exemplo em 1º de setembro de 2026, quando o painel abre, então mostra limite da semana de R$ 196,00 (terça a domingo), sobra planejada de R$ 558,00 e 52% da renda comprometida.
- Dado nenhuma renda cadastrada, quando o painel abre, então os percentuais não aparecem e o app pede a renda, sem dividir por zero (RN-604).
