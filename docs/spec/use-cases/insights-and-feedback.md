# Casos de uso — retorno e relatórios

Formato e convenções em [use-cases.md](../use-cases.md). Regras em [feedback.md](../rules/feedback.md); textos completos de cada resumo em [feedback.md](../feedback.md).

Todos os resumos existem no Android e na web. Notificação é só do Android.

## UC-INS-01 — Ver o resumo do dia

**Plataforma:** ambas · **Grava:** nada · **Regras:** RN-810 a RN-815, RN-804

**Aceite:**
- Dado sábado, 19/09, com mercado de R$ 38,40 e ônibus de R$ 8,50 no Pix, quando o resumo abre, então diz "Hoje: R$ 46,90 em 2 lançamentos. Sobram R$ 106,47 até domingo."
- Dado o mesmo mercado pago no vale, quando o resumo abre, então diz "R$ 8,50 em dinheiro e R$ 38,40 no vale" — os dois valores nunca somados — e o resta na semana é R$ 144,87.
- Dado um dia sem lançamento, quando o resumo abre, então diz "Nada lançado hoje." e nada mais.
- Dado uma instalação nova, quando um dia termina, então **nenhuma** notificação diária é enviada (RN-813 ⚑ validar).
- Dado a IA fora do ar, quando o resumo abre, então é idêntico: o diário nunca usa IA (RN-815).

## UC-INS-02 — Receber e ver o resumo da semana

**Plataforma:** ambas · **Grava:** `ReminderShown` ao notificar · **Regras:** RN-820 a RN-825, RN-806, RN-807, RN-843

**Aceite:**
- Dado a semana de 7 a 13/09 com R$ 260,00 gastos de R$ 236,25, quando o resumo abre, então diz que passou R$ 23,75, que a próxima é R$ 226,47 e que "o limite ficou R$ 9,78 menor do que seria".
- Dado a mesma semana, quando a notificação chega na tela bloqueada, então diz "Resumo da semana pronto. Limite da próxima: R$ 226,47." — o quanto passou não aparece.
- Dado a semana de 14 a 20/09 com R$ 200,00 de R$ 226,47, quando o resumo abre, então constata o fato e o novo limite de R$ 245,00, sem "parabéns" e sem medalha.
- Dado um lançamento feito no domingo às 23h, quando o resumo é reaberto, então já está recalculado, e o limite da segunda também.
- Dado três dias seguidos sem lançamento, quando o resumo abre, então informa "Nenhum lançamento de quarta a sexta. Se faltou algum, dá para lançar agora com a data certa.", sem acusar.
- Dado "Ver a conta", quando tocado, então mostra o restante do variável, os dias que faltam e a divisão que deu o limite.

## UC-INS-03 — Receber e ver o fechamento do mês

**Plataforma:** ambas para ver; Android para fechar (UC-BUDG-05) · **Regras:** RN-830 a RN-838

**Aceite:**
- Dado 1º de outubro, quando o dia começa, então chega uma vez "Setembro está pronto para fechar. Leva 2 minutos para conferir."
- Dado o fechamento aberto, quando lido, então tem duas partes nesta ordem — "Como foi setembro" e "Como fica adiante" — e a primeira começa pelo que foi cumprido.
- Dado lazer de R$ 240 em agosto e R$ 310 em setembro, e luz de R$ 150 para R$ 158, quando a comparação aparece, então lazer entra (+R$ 70, +29%) e luz não (RN-834).
- Dado o fechamento, quando as sugestões aparecem, então são no máximo três, cada uma com valor, e nenhuma é aplicada sozinha.
- Dado o mês com falta, quando o fechamento abre, então nenhuma frase atribui falha à pessoa, e a falta vem com o que dá para fazer.

## UC-INS-04 — Receber um lembrete de vencimento

**Plataforma:** Android · **Grava:** `ReminderShown` · **Regras:** RN-840 a RN-849

**Aceite:**
- Dado o aluguel do dia 10, quando chegam os dias 8 e 10, então há um lembrete em cada um, e nenhum no dia 11.
- Dado o mês com sobra, quando o lembrete chega, então traz o contexto: "Aluguel de R$ 1.100,00 vence quinta, 10. Pelo que está lançado, o mês continua com sobra de R$ 558,00."
- Dado o mês com falta de R$ 142, quando o lembrete da parcela chega, então o texto dentro do app diz a falta e oferece "Ver os ajustes"; na tela bloqueada aparece só "Parcela do empréstimo vence terça, 15."
- Dado qualquer lembrete, quando lido, então a frase "pelo que está lançado" deixa claro que é estimativa (RN-841).
- Dado o lembrete da fatura, quando tocado, então abre a fatura, depois do desbloqueio (RN-849).
- Dado "ocultar valores nas notificações" ligado, quando qualquer aviso chega, então nenhum valor aparece (RN-844).
- Dado cinco vencimentos avisados no mês, quando o fechamento abre, então mostra quantos foram pagos em dia (RN-848).

## UC-INS-05 — Alternar entre relatório simplificado e detalhado

**Plataforma:** ambas · **Grava:** nada (preferência local) · **Regras:** RN-860, RN-863, RN-864

**Aceite:**
- Dado o fechamento no nível simplificado, quando aberto, então mostra resultado, os três blocos, o vale e as sugestões.
- Dado a troca para detalhado, quando feita, então aparecem categorias, comparação com o mês anterior, fora do padrão, custo por dia e lançamentos — e **nenhum número** muda.
- Dado a preferência escolhida, quando o app é reaberto, então ela foi lembrada.

## UC-INS-06 — Escolher entre mais visual e mais numérico

**Plataforma:** ambas · **Grava:** nada (preferência local) · **Regras:** RN-861, RN-862

**Aceite:**
- Dado "mais visual", quando o fechamento abre, então começa com uma barra empilhada — fixos, variáveis e dívidas sobre a renda em dinheiro — e o vale em barra **separada**; cada segmento tem o valor escrito.
- Dado "mais numérico", quando o fechamento abre, então a mesma informação vem em tabela, com algarismos tabulares.
- Dado qualquer gráfico, quando lido por leitor de tela, então o número equivalente é anunciado (RNF-A11Y-20).
- Dado qualquer tela, quando inspecionada, então não há gráfico onde não existe parte-todo nem progresso.
