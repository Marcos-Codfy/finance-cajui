# RN-6xx — Indicadores

Formato e convenções em [README.md](README.md). Termos em [glossary.md](../glossary.md). O [exemplo completo](#exemplo-completo) no fim do arquivo usa os mesmos números em todas as regras e vira a base dos testes.

## Princípios

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-601 | Todo indicador é função pura dos eventos do log: os mesmos eventos produzem os mesmos números, no app e no servidor | Recalcular setembro a partir do log reproduz o snapshot centavo a centavo | modelagem |
| RN-602 | A IA nunca calcula indicador. Número exibido ou dito pelo assistente vem sempre do cálculo determinístico | O chat responde "sobram R$ 558" porque recebeu R$ 558 calculados, não porque somou | prompt · D-UX-23 |
| RN-603 | Cada parcela do cálculo usa o valor **real quando conhecido** e o **esperado enquanto não for**: renda (RN-131), fixo (RN-411) e, no variável, o maior entre o gasto e o máximo da faixa | Dia 12 do mês: salário já recebido usa o real; segunda renda do dia 20 usa o esperado | modelagem |
| RN-604 | Indicador de proporção sobre a renda é **indefinido** quando a renda em dinheiro do mês é zero. O app pede a renda; nunca divide por zero nem mostra 0% ou ∞ | Primeiro uso sem renda cadastrada: "Cadastre sua renda para ver quanto dela está comprometido" | modelagem |
| RN-605 | Todo indicador existe por moeda; nenhum soma dinheiro e vale (RN-111) | Custo por dia: dois números, um por moeda | prompt |

## Entradas do mês

| ID | Regra | Fórmula | Origem |
|---|---|---|---|
| RN-610 | **Renda em dinheiro** do mês | `RC` = soma das fontes em dinheiro (RN-603) + entradas avulsas do mês | prompt |
| RN-611 | **Vale disponível** no mês | `VA` = saldo do vale no início do mês + créditos do mês | prompt · decisão 2026-09-19 |

## Sobra ou falta

| ID | Regra | Fórmula | Origem |
|---|---|---|---|
| RN-620 | **Resultado planejado** do mês, em dinheiro | `P = RC − F − D − Vd`, em que `F` = fixos, `D` = parcelas de dívida do mês, `Vd` = variáveis pelo pior caso **na parte em dinheiro** (RN-425) | prompt |
| RN-621 | **Resultado projetado**, recalculado a cada lançamento | Mesma fórmula, com RN-603: em cada variável entra `máx(gasto, máximo)`; lançamento fora do plano entra inteiro (RN-424) | modelagem |
| RN-622 | Resultado ≥ 0 é **sobra**; resultado < 0 é **falta**, exibida pelo valor absoluto. Resultado zero é "o mês fecha no zero" | P = −142 → "Faltam R$ 142 para fechar o mês" | prompt · D-UX-22 |
| RN-623 | **Resultado realizado**, no fechamento | Renda em dinheiro recebida − despesas em dinheiro contadas no mês (RN-250, RN-310, RN-504) | prompt |

## Comprometimento da renda

| ID | Regra | Fórmula | Origem |
|---|---|---|---|
| RN-630 | **Comprometimento total** | `(F + D) ÷ RC` | prompt |
| RN-631 | **Comprometimento por grupo**, para moradia, transporte, assinaturas e dívidas | Soma do valor planejado em dinheiro das categorias do grupo `÷ RC`. Variável entra pelo pior caso em dinheiro | prompt |
| RN-632 | Percentual é exibido como inteiro, com meio ponto para cima | 51,94% → "52%" | modelagem |
| RN-633 | O grupo "dívidas" inclui parcelamentos de cartão (RN-312) | Empréstimo R$ 212 + geladeira R$ 150 = R$ 362 | modelagem ⚑ validar |

## Limite semanal

> **Revogado em 11/10/2026**, a pedido do dono ("aquele item de quanto eu posso gastar na semana retire, na prática eu não uso e nem é útil pra mim"). As regras ficam como registro. O que delas vale para o mês continua valendo, testado sem a semana: o que conta como rotina (RN-643), a compra à vista no cartão na data da compra (RN-310) e o fora do padrão fora da rotina (RN-648).

| ID | Regra | Fórmula ou exemplo | Origem |
|---|---|---|---|
| RN-640 | **Orçamento variável em dinheiro** do mês | `VB = Vd` (RN-620) + provisão de fora do padrão, se adotada (RN-432) | prompt |
| RN-641 | **Revogada em 11/10/2026.** **Limite da semana**, calculado no início de cada semana de calendário (ou no dia 1, para a primeira) | `limite = ⌊ restante × dias_da_semana_no_mês ÷ dias_restantes_no_mês ⌋`, em que `restante = VB −` variável em dinheiro gasto no mês antes do início da semana | decisão 2026-09-19 |
| RN-642 | **Revogada em 11/10/2026.** **Resta na semana** | `limite −` variável em dinheiro gasto na semana. Negativo é exibido como "a semana passou R$ X do limite" | prompt |
| RN-643 | Conta no gasto da semana toda linha de pagamento **em dinheiro**, de lançamento do bloco **variável**, pela **data da compra** — inclusive compra à vista no cartão (RN-310). Não contam: vale, fixos, dívidas, parcelas e lançamento marcado como fora do padrão (RN-648) | Mercado de R$ 186,40 no crédito em 12/09 reduz o limite da semana de 07 a 13/09 | decisão 2026-09-19 |
| RN-644 | **Revogada em 11/10/2026.** Semana partida pela virada do mês pertence a cada mês só pelos dias que estão nele; cada parte tem seu próprio limite | 28 a 30/09 é uma semana de 3 dias em setembro; 01 a 04/10 é uma de 4 dias em outubro | decisão 2026-09-19 |
| RN-645 | **Revogada em 11/10/2026.** Se o `restante` for zero ou negativo, o limite da semana é zero e o painel mostra o quanto o variável já passou do plano, em tom neutro | "O variável do mês já passou R$ 40 do plano" | D-UX-22 |
| RN-646 | **Revogada em 11/10/2026.** O limite é função dos lançamentos **anteriores** ao início da semana. Lançamento tardio com data de semana passada recalcula o limite da semana corrente | Lançar hoje um gasto de R$ 50 de terça passada reduz o limite desta semana | modelagem |
| RN-647 | **Revogada em 11/10/2026.** O limite semanal é informação, não bloqueio: nenhum lançamento é recusado por ultrapassá-lo | — | D-UX-18 |
| RN-648 | Lançamento marcado como **fora do padrão** (RN-240) conta inteiro no resultado projetado do mês (RN-621), mas fica fora do gasto da semana e do `restante` da RN-641. O limite semanal governa o gasto de rotina; o susto aparece onde pode ser resolvido, em "quanto falta ajustar" | Conserto de R$ 700 no dia 3, marcado fora do padrão: o mês passa a ter falta de R$ 142 e o limite da semana continua R$ 196,00. Sem a marca, a semana apareceria R$ 504 acima do limite | modelagem ⚑ validar |

## Custo de vida por dia

| ID | Regra | Fórmula | Origem |
|---|---|---|---|
| RN-650 | **Planejado**, por moeda | Dinheiro: `(F + D + Vd) ÷ dias do mês`. Vale: `mín(VA, pior caso das categorias elegíveis) ÷ dias do mês` | prompt |
| RN-651 | **Realizado**, por moeda | Despesas contadas no mês até hoje `÷` dias decorridos, contando hoje | prompt |
| RN-652 | O custo por dia é média do período. O app não destaca o gasto de hoje nem compara dia contra dia | — | D-UX-17 |

## Quanto falta ajustar

| ID | Regra | Fórmula | Origem |
|---|---|---|---|
| RN-660 | **Ajuste necessário** | `A = máx(0, −resultado projetado)` | prompt |
| RN-661 | **Folga ajustável** | `S` = soma, nos variáveis, de `máx(0, máximo − máx(gasto, mínimo))`, na parte em dinheiro | modelagem |
| RN-662 | Se `A ≤ S`, o mês fecha ajustando variáveis, e o app lista os ajustes possíveis do maior para o menor. Se `A > S`, o app diz com clareza que os variáveis cobrem só `S` e que o restante, `A − S`, depende de renda, de fixo ou de dívida | A = 142, S = 540: "Dá para cobrir sem mexer nos fixos" | prompt · D-UX-22 |
| RN-663 | Nenhum ajuste é aplicado sozinho. Aceitar uma sugestão altera o plano do mês como ação explícita e registrada | — | D-UX-04 |

## O que o painel mostra primeiro

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-670 | **Revogada em 11/10/2026.** O número principal do painel é o **resta na semana** (RN-642), que continua útil com o mês no negativo. Sobra ou falta do mês e comprometimento ficam no segundo nível da mesma tela, visíveis sem toque | O painel abre em "Sobram R$ 412 até domingo", nunca em "Faltam R$ 142" | D-UX-01 |
| RN-671 | Falta, dívida e limite ultrapassado nunca dependem só de cor: levam sinal, rótulo e ícone | — | D-UX-02 · D-WCAG |

## Exemplo completo

Setembro de 2026 tem 30 dias e começa numa terça-feira.

**Entradas.** Salário R$ 2.400 + segunda renda R$ 800 → `RC = 3.200`. Vale: saldo de R$ 50 + crédito de R$ 600 → `VA = 650`.

**Fixos.** Aluguel 1.100 · internet 100 · streaming 40 · celular 60 → `F = 1.300`.

**Dívidas.** Empréstimo 212 · parcela da geladeira 150 → `D = 362`.

**Variáveis** (faixa): mercado 500–800, elegível ao vale · transporte 180–260 · lazer 100–250 · farmácia 50–150 · luz 110–170.

| Cálculo | Conta | Resultado |
|---|---|---|
| Mercado em dinheiro (RN-425) | máx(0, 800 − 650) | **150,00** |
| `Vd` | 260 + 250 + 150 + 170 + 150 | **980,00** |
| Resultado planejado (RN-620) | 3.200 − 1.300 − 362 − 980 | **sobra de 558,00** |
| Comprometimento total (RN-630) | 1.662 ÷ 3.200 = 51,94% | **52%** |
| Moradia (aluguel + luz) | 1.270 ÷ 3.200 = 39,69% | **40%** |
| Transporte | 260 ÷ 3.200 = 8,13% | **8%** |
| Assinaturas (internet, streaming, celular) | 200 ÷ 3.200 = 6,25% | **6%** |
| Dívidas | 362 ÷ 3.200 = 11,31% | **11%** |
| Custo por dia, dinheiro (RN-650) | 2.642 ÷ 30 = 88,0667 | **88,07** |
| Custo por dia, vale | 650 ÷ 30 = 21,6667 | **21,67** |

**Limite semanal** (RN-641), com `VB = 980`:

| Semana | Dias no mês | Dias restantes | Restante | Limite | Gasto na semana |
|---|---|---|---|---|---|
| 01–06/09 (ter a dom) | 6 | 30 | 980,00 | **196,00** | 170,00 |
| 07–13/09 | 7 | 24 | 810,00 | **236,25** | 260,00 |
| 14–20/09 | 7 | 17 | 550,00 | **226,47** | 200,00 |
| 21–27/09 | 7 | 10 | 350,00 | **245,00** | 230,00 |
| 28–30/09 (seg a qua) | 3 | 3 | 120,00 | **120,00** | — |

A segunda semana passou R$ 23,75 do limite; em vez de virar bronca, o excesso se diluiu nas seguintes. A semana boa faz o contrário: aumenta o limite das próximas.

**Quanto falta ajustar.** Um conserto de R$ 700 fora do plano, no dia 3, antes de qualquer outro gasto:

| Cálculo | Conta | Resultado |
|---|---|---|
| Resultado projetado (RN-621) | 558 − 700 | **falta de 142,00** |
| Ajuste necessário (RN-660) | máx(0, 142) | **142,00** |
| Folga ajustável (RN-661) | (260−180) + (250−100) + (150−50) + (170−110) + (150−0) | **540,00** |
| Conclusão (RN-662) | 142 ≤ 540 | fecha ajustando variáveis |

A folga do mercado é R$ 150 porque, gastando o mínimo da faixa (R$ 500), o vale de R$ 650 cobre tudo e nenhum dinheiro é usado.
