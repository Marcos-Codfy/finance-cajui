# Meu mês — o modelo da planilha (RN-1000 a RN-1099)

Em 11/10/2026 o dono simplificou o controle e mandou as regras do app junto com a planilha que ele usa, com quatro abas: Meu Mês, Minhas Contas, Minhas Dívidas e Mês a Mês. Estas regras **substituem** as de orçamento por faixas, ajustes e fechamento manual do mês (`blocks-and-budget.md`, RN-4xx e RN-6xx que falam de mínimo, máximo, folga e fechamento). O resto da especificação continua valendo: cartão, vale, captura, assistente.

Os números de exemplo abaixo são **inventados**. A planilha do dono tem dados reais e nunca entra no repositório.

## Conceitos

| ID | Regra | Exemplo | Origem |
|---|---|---|---|
| RN-1001 | Cartão de crédito não é despesa, é forma de pagamento. Todo lançamento guarda o que foi comprado e por onde foi pago. A fatura é visão derivada, nunca uma linha de despesa | "Fatura do Nubank: R$ 250" não pode ser lançado | regra 1 do dono · RN-207 |
| RN-1002 | Dívida é só o que atravessa mais de um mês: parcelamento, carnê, conta atrasada, rotativo. Tem saldo, parcela por mês, tipo (parcelado, atrasado ou rotativo) e ordem de quitação. Compra no cartão paga inteira na fatura seguinte é gasto do mês | Conta atrasada de R$ 3.800, sem parcela; carnê de R$ 120 por mês | regra 2 |
| RN-1003 | O que sai está em exatamente quatro grupos: conta fixa, assinatura, dia a dia e parcela de dívida. A parcela de dívida vem da dívida cadastrada e nunca é digitada | Aluguel é conta fixa; Uber é dia a dia | regra 3 |
| RN-1004 | "Minhas contas" é uma lista de linhas: o que é, quanto por mês, grupo (conta fixa, assinatura ou dia a dia), onde se paga e uma observação. O valor é a estimativa maior; zero vale e significa "conta só o que for gasto". Cada linha aponta para uma categoria | Energia de R$ 170 a R$ 200 entra por R$ 200 | aba Minhas Contas |
| RN-1005 | Em cada categoria, o mês conta o maior entre o previsto e o gasto de verdade, nas duas moedas | Mercado previsto R$ 600, gasto R$ 700: conta R$ 700. Transporte previsto R$ 400, gasto R$ 150: conta R$ 400 | "use o maior" |
| RN-1006 | O que entra: um salário por pessoa da casa (o recebido substitui o esperado), as entradas avulsas do mês e o vale. O vale do mês é o que foi creditado no mês; sem crédito registrado, o do plano | Salários de R$ 1.800 e R$ 1.500; vale de R$ 500 | regra 4 · RN-131 |
| RN-1007 | Lançamento numa categoria de dívida sem dívida ligada (juros, tarifa) é gasto do dia a dia; pagamento de parcela ligado a uma dívida não conta de novo | Tarifa de R$ 30 entra no dia a dia | regra 3 |

## As contas do mês

Todas são função pura do domínio (`MonthBudget`), as mesmas no celular, na web e no servidor.

| ID | Regra | Exemplo (casa inventada) |
|---|---|---|
| RN-1010 | `dinheiro = salários + extras` | 1.800 + 1.500 = 3.300 |
| RN-1011 | `total que sai = fixas + assinaturas + dia a dia + parcelas + dízimo` | 1.270 + 60 + 1.100 + 120 + 330 = 2.880 |
| RN-1012 | `coberto pelo vale = min(vale, gasto com comida)`. Comida são as categorias que o vale paga (RN-112) | min(500, 600) = 500 |
| RN-1013 | `sai do bolso = total que sai − coberto pelo vale` | 2.880 − 500 = 2.380 |
| RN-1014 | `resultado = dinheiro − sai do bolso`. Zero ou mais: o mês fecha. Negativo: falta `−resultado` para fechar | 3.300 − 2.380 = 920, fecha. Com R$ 2.000 de renda: faltam 250 |
| RN-1015 | `pode gastar por semana = max(0, dinheiro − fixas − assinaturas − parcelas − dízimo + coberto) ÷ 4`, arredondado para baixo. A tela mostra à parte quanto disso é vale (RN-111) | (3.300 − 1.270 − 60 − 120 − 330 + 500) ÷ 4 = 505, sendo 125 de vale |
| RN-1016 | `já está gasto = sai do bolso ÷ dinheiro`, em percentual inteiro. Passa de 100% quando o mês não fecha. Sem renda, não há percentual | 2.380 ÷ 3.300 = 72% |
| RN-1017 | Dízimo é um percentual configurável da renda em dinheiro, guardado em centésimos de por cento. Pode ser zero | 10% de 3.300 = 330 |
| RN-1018 | A semana começa na segunda-feira, ou no dia 1 se o mês começou no meio dela. O gasto da semana é o do dia a dia, nas duas moedas, porque o limite também conta o vale | Segunda 19/10 a terça 20/10: R$ 130 de 505, restam 375 |

## Cartões

| ID | Regra | Exemplo |
|---|---|---|
| RN-1020 | Cada cartão tem limite, fechamento e vencimento. `usado no mês` = soma dos lançamentos do mês pagos com o cartão, menos estornos; a compra parcelada conta inteira no mês da compra. `sobra = limite − usado`. Aviso a partir de 50% e de 80% do limite, comparando centavos | Limite R$ 1.000: R$ 499,99 sem aviso; R$ 500,00 aviso de metade; R$ 800,00 aviso alto |

## Dívidas

| ID | Regra | Exemplo |
|---|---|---|
| RN-1030 | O saldo cai pelo calendário: a parcela nunca é digitada. Na parcelada, conta o maior entre as parcelas que a pessoa disse ter pago no cadastro e as que já venceram. Na de saldo informado, o saldo cai uma parcela a cada vencimento depois do dia informado, e nunca fica negativo | Saldo de R$ 1.000, parcela de R$ 300, dia 5: R$ 700 em 05/10 e zero em fevereiro |
| RN-1031 | A ordem de quitação é uma lista de dívidas; as que ela não cita vêm depois, na ordem em que foram cadastradas. Vale a lista mais nova inteira | "Primeiro a conta atrasada, depois o carnê" |
| RN-1032 | "Quanto ainda devo" no fim de um mês soma o saldo das dívidas e as parcelas de cartão que vencem depois dele | — |

## Mês a mês e plano

| ID | Regra | Exemplo |
|---|---|---|
| RN-1040 | O "Mês a mês" é calculado, nunca fechado à mão: para cada mês, do primeiro com algum fato até o atual, entrou (dinheiro), saiu (do bolso), sobrou ou faltou, e quanto ainda se devia no fim. Cada mês usa o plano que valia nele. Um lançamento atrasado muda o mês dele sozinho | — |
| RN-1050 | O plano não é obrigatório: sem ele, o mês conta só o que aconteceu. Depois de 30 dias de uso sem nenhuma conta cadastrada, o app sugere as contas pelo gasto dos últimos 30 dias, arredondando cada uma para cima, de dez em dez reais | R$ 523,40 de mercado vira R$ 530 |
| RN-1051 | O plano antigo é lido como o novo: a renda vira o primeiro salário (mesmo identificador, para o salário recebido continuar substituindo o esperado); cada fixo vira conta fixa; cada variável vira dia a dia pelo máximo; as parcelas digitadas soltas continuam contando até a pessoa salvar um plano novo | — |

## Linguagem

| ID | Regra |
|---|---|
| RN-1060 | A tela usa as palavras da planilha: "o que entra", "o que sai", "sobrou ou faltou", "pode gastar por semana", "já está gasto". Nada de "déficit", "comprometimento", "provisionamento" ou "pior caso". Tom descritivo, nunca de culpa |
