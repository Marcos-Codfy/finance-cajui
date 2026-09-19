# RN-2xx — Lançamentos e pagamentos

Formato e convenções em [README.md](README.md). Termos em [glossary.md](../glossary.md).

O centro desta área é a separação que dá sentido ao produto: **o que foi comprado** é o lançamento; **por onde foi pago** são as linhas de pagamento.

## O lançamento

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-201 | Todo lançamento registra o que foi comprado: descrição, valor, data da compra e categoria | "Mercado Boa Compra" · R$ 186,40 · 2026-09-12 · mercado | prompt |
| RN-202 | Toda categoria pertence a exatamente um bloco e a exatamente um grupo. O bloco do lançamento é o da sua categoria | "mercado" → bloco variável, grupo alimentação. "aluguel" → bloco fixo, grupo moradia | modelagem |
| RN-203 | Todo lançamento tem uma ou mais linhas de pagamento, e a soma das linhas é exatamente igual ao valor do lançamento | R$ 86,00 = R$ 30,00 no vale + R$ 56,00 no Pix. Soma diferente é rejeitada | prompt |
| RN-204 | Um lançamento pode ser pago por mais de uma forma de pagamento | O caso típico é o vale que acaba no meio da compra (RN-122) | modelagem |
| RN-205 | Toda linha de pagamento aponta para uma forma de pagamento, e a moeda da linha é a moeda dessa forma | Linha paga com "Vale" é `mealVoucher`; com "Pix", "débito", "dinheiro vivo", "boleto" ou "cartão de crédito" é `cash` | modelagem |
| RN-206 | A data da compra não pode estar no futuro, no fuso de negócio. Compromisso futuro é item de plano, não lançamento | Lançar hoje uma compra com data de amanhã é rejeitado | modelagem |
| RN-207 | Não existe categoria, bloco ou lançamento que represente cartão de crédito ou fatura | Uma proposta de classificação "fatura do cartão" como despesa é inválida por construção (RN-301, RN-310) | prompt |

## Correção e estorno

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-208 | Lançamento é fato imutável no log. Editar gera um evento de correção; apagar gera um evento de cancelamento. O original permanece, e as visões mostram o estado mais recente | Trocar a categoria de "lazer" para "transporte" deixa no log o lançamento original e a correção, com data e motivo | modelagem · D-UX-07 |
| RN-209 | Estorno é um registro próprio, ligado ao lançamento original, de valor igual ou menor que o dele. Reduz o gasto da categoria no mês da **data do estorno** | Compra de R$ 120 em agosto, devolução de R$ 120 em setembro: agosto não muda; setembro tem −R$ 120 na categoria | modelagem |
| RN-210 | A soma dos estornos de um lançamento nunca ultrapassa o valor dele | Segundo estorno que passe do total é rejeitado | modelagem |
| RN-211 | O estorno volta pela mesma forma de pagamento e na mesma moeda da linha estornada | Estorno de compra no vale devolve saldo ao vale (RN-120) | modelagem |

## Duplicidade

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-220 | O mesmo arquivo compartilhado duas vezes é reconhecido pelo resumo criptográfico do conteúdo, e o app avisa antes de propor novo lançamento | Compartilhar o mesmo PDF de novo: "Este comprovante já virou um lançamento em 12/09. Quer abrir?" | modelagem |
| RN-221 | Lançamento com mesmo valor, mesma data e estabelecimento equivalente a outro já existente gera **aviso** de possível repetição, nunca bloqueio nem descarte silencioso | Dois cafés de R$ 8,50 no mesmo dia são legítimos: o app pergunta, o usuário decide | modelagem |

## O que não é lançamento

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-230 | Saque e transferência entre contas próprias não são lançamentos: o dinheiro não saiu do domicílio | Sacar R$ 100 não gera nada; o que for comprado com eles gera lançamento pago em "dinheiro vivo" | modelagem |
| RN-231 | Pagamento de fatura de cartão não é lançamento: é liquidação (RN-308) | — | prompt |
| RN-232 | Recebimento de renda não é lançamento (RN-132) | — | modelagem |
| RN-233 | Ajuste de saldo do vale não é lançamento (RN-123) | — | modelagem |

## Fora do padrão

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-240 | "Fora do padrão" é um atributo do lançamento, independente da categoria, para que gastos que não se repetem possam ser somados entre categorias | Conserto do celular (categoria "manutenção") e presente de casamento (categoria "presentes") entram no mesmo acumulado de fora do padrão | D-UX-11 |
| RN-241 | Ao marcar um lançamento como fora do padrão, o app mostra o acumulado do ano e a média mensal desses gastos | "4º gasto fora do padrão do ano; somam R$ 1.310 (média de R$ 146 por mês)" | D-UX-11 · Sussman2012 |

## Em que mês um lançamento conta

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-250 | Linha de pagamento em dinheiro vivo, Pix, débito, boleto ou vale conta no mês da data da compra | Pix em 30/09 conta em setembro | modelagem |
| RN-251 | Linha de pagamento em cartão de crédito segue as regras RN-304 (à vista) e RN-305 (parcelada) | — | decisão 2026-09-19 |
| RN-252 | Lançamento com data em mês já fechado é aceito como **lançamento tardio** e gera uma revisão do fechamento (RN-411); o fechamento original é preservado | Em 03/10, lançar uma compra de 28/09: setembro ganha a revisão 2 | modelagem |
