# RN-1xx — Dinheiro, renda e as duas moedas

Formato e convenções em [README.md](README.md). Termos em [glossary.md](../glossary.md).

## Valor monetário

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-101 | Todo valor é um inteiro de centavos em reais. Nenhuma operação de dinheiro usa ponto flutuante, em nenhuma camada | `Money.fromCents(128450)` é R$ 1.284,50. `0.1 + 0.2` nunca aparece no caminho de um valor | modelagem |
| RN-102 | Dividir um valor em N partes produz partes cuja soma é exatamente o total: o resto em centavos vai, um a um, para as primeiras partes | R$ 100,00 em 3 → 33,34 · 33,33 · 33,33 | modelagem |
| RN-103 | Onde um cálculo gera fração de centavo fora de um rateio, arredonda-se para o centavo mais próximo, com meio centavo para cima; limites de gasto arredondam para **baixo** | 88,0666… → R$ 88,07; limite de 226,4705… → R$ 226,47 | modelagem |
| RN-104 | Valor monetário de lançamento é sempre maior que zero. Redução se expressa por estorno (RN-209), nunca por valor negativo | Lançamento de R$ 0,00 ou negativo é rejeitado | modelagem |

## As duas moedas

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-110 | Todo valor pertence a exatamente uma moeda: `cash` (dinheiro) ou `mealVoucher` (vale) | Uma linha de pagamento nunca é "meio dinheiro, meio vale"; seriam duas linhas | prompt |
| RN-111 | Nenhum total — calculado, armazenado ou exibido — soma as duas moedas. Todo agregado existe por moeda | Não existe "saldo total" nem "renda total"; existem renda em dinheiro e renda em vale | prompt · D-UX-03 |
| RN-112 | O vale só paga lançamento cuja categoria está marcada como elegível ao vale | Pagar "internet" com vale é rejeitado | prompt |
| RN-113 | A elegibilidade ao vale é um atributo da categoria, configurável. Nascem elegíveis: mercado, feira, açougue, padaria e hortifrúti | Se o cartão do vale for aceito em restaurante, o usuário marca "restaurante" como elegível | modelagem |
| RN-114 | Sobra de vale não compensa falta em dinheiro, em nenhum indicador | Vale com R$ 200 de folga e mês com falta de R$ 150 em dinheiro: a falta continua R$ 150 | prompt · D-UX-03 |

## Saldo do vale

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-120 | Saldo do vale = saldo anterior + créditos − linhas de pagamento em vale + estornos em vale + ajustes | Saldo 50 + crédito 600 − compras 480 = R$ 170 | modelagem |
| RN-121 | O saldo do vale passa inteiro de um mês para o outro | Setembro termina com R$ 170; outubro começa com R$ 170 + o crédito do mês | decisão 2026-09-19 |
| RN-122 | ~~Substituída pela RN-1019 (11/10/2026)~~ O saldo do vale nunca fica negativo. Linha de pagamento em vale maior que o saldo é rejeitada, e o app oferece dividir o pagamento (RN-204) | Saldo R$ 30, compra de R$ 86: o app propõe R$ 30 no vale e R$ 56 em dinheiro | modelagem |
| RN-123 | Como não há integração com a operadora, o usuário pode corrigir o saldo informando o valor real. A correção é um evento de **ajuste**, com motivo; não é renda nem despesa e não entra em indicador | Saldo calculado R$ 170, saldo real R$ 162,10: ajuste de −R$ 7,90, motivo "taxa da operadora" | modelagem |
| RN-124 | Fato já registrado nunca é recusado ao reler o registro nem ao chegar de outro aparelho. Se os pagamentos em vale registrados passam do saldo — dois aparelhos gastaram o mesmo saldo sem rede —, o saldo mostrado é zero e a diferença fica guardada como **a descoberto**; o crédito, o estorno ou o ajuste seguinte cobre primeiro o descoberto. A conta dá o mesmo resultado em qualquer ordem de chegada dos fatos, no aparelho e no servidor. A tela avisa e oferece acertar o saldo (RN-123). Pagamento **novo** continua seguindo a RN-122 | Crédito de R$ 100; o celular A lança R$ 80 no vale e o B, sem rede, outros R$ 80: saldo R$ 0,00, com R$ 60,00 a descoberto. Chega o crédito de R$ 50: saldo R$ 0,00, com R$ 10,00 a descoberto | decisão 2026-09-29, por delegação · ADR-019 |

## Fontes de renda

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-130 | O domicílio tem uma ou mais fontes de renda. Cada fonte tem nome, moeda, valor esperado e dia esperado | "Salário" R$ 2.400 dia 5 · "Segunda renda" R$ 800 dia 20 · "Vale" R$ 600 dia 1 | prompt |
| RN-131 | O plano do mês usa o valor **esperado** de cada fonte ativa. Quando o recebimento do mês é registrado, o valor **recebido** substitui o esperado nos cálculos daquele mês | Esperado 2.400, recebido 2.310 (desconto): o mês passa a calcular com 2.310 | modelagem |
| RN-132 | Recebimento não é lançamento. Renda e despesa são tipos distintos e nunca se compensam dentro de uma categoria | Não existe categoria "salário" | modelagem |
| RN-133 | Entrada avulsa (venda de um objeto, devolução de empréstimo feito a alguém) é um recebimento sem fonte, contado só no mês em que ocorre e nunca projetado para os meses seguintes | R$ 150 de uma venda em setembro não aparecem no plano de outubro | modelagem |
| RN-134 | Desativar uma fonte vale a partir de um mês informado; os meses anteriores não mudam | Fonte desativada a partir de novembro: outubro continua contando com ela | modelagem |
| RN-135 | Um mês sem nenhuma renda em dinheiro esperada nem recebida tem os indicadores de proporção indefinidos (RN-604), nunca divididos por zero | Primeiro uso, antes de cadastrar renda: o painel pede a renda em vez de mostrar "NaN%" | modelagem |
