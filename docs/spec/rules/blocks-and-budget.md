# RN-4xx — Blocos e orçamento do mês

Formato e convenções em [README.md](README.md). Termos em [glossary.md](../glossary.md).

## Os três blocos

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-401 | Toda despesa pertence a exatamente um de três blocos: **fixos**, **variáveis** ou **dívidas** | Não existe despesa "sem bloco" nem bloco "outros" | prompt |
| RN-402 | Cada bloco tem limite e acompanhamento próprios. Nenhuma tela usa um saldo único consolidado como número principal | O painel mostra três partições, não "gastos totais" | D-UX-04 |
| RN-403 | Folga de um bloco não cobre estouro de outro automaticamente. Cobrir é um **remanejamento**: ação explícita do usuário, registrada como evento, com origem, destino, valor e mês | Mover R$ 80 da folga de "lazer" para "transporte" em setembro fica no log e aparece no fechamento | D-UX-04 |

## Fixos

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-410 | Um fixo tem nome, valor, dia de vencimento, categoria e forma de pagamento habitual. Todo mês ele gera uma **ocorrência esperada** no plano | "Aluguel" · R$ 1.100 · dia 10 · moradia · Pix | prompt |
| RN-411 | A ocorrência do mês é dada como paga quando um lançamento é ligado a ela. O valor pago pode diferir do esperado; o mês passa a calcular com o valor pago | Internet esperada R$ 100, paga R$ 104,90: o mês usa R$ 104,90 | modelagem |
| RN-412 | Mudar o valor de um fixo vale a partir de um mês informado. Meses anteriores e fechamentos não mudam | Aluguel passa a R$ 1.180 a partir de janeiro | modelagem |
| RN-413 | Conta cujo valor muda todo mês não é fixo, por mais regular que seja: é variável com faixa estreita | Conta de luz: variável, faixa R$ 110–170 | prompt |
| RN-414 | Ocorrência vencida e ainda sem lançamento aparece como "**em aberto**", sem cálculo automático de multa ou juros; o usuário informa o que pagou | Aluguel do dia 10 sem lançamento no dia 12: "em aberto desde 10/09" | modelagem |
| RN-415 | Encerrar um fixo vale a partir de um mês informado; o histórico permanece | Assinatura cancelada em outubro some do plano de novembro | modelagem |

## Variáveis

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-420 | Um variável é uma categoria com faixa mínima–máxima, em que 0 ≤ mínimo ≤ máximo | "Mercado" R$ 500–800 | prompt |
| RN-421 | O orçamento do mês usa sempre o **máximo** da faixa — o pior caso | Mercado entra no plano como R$ 800 | prompt |
| RN-422 | Gastar menos que o máximo gera sobra no fim do mês. A sobra não é transportada para o mês seguinte como orçamento extra | Mercado fecha em R$ 640: R$ 160 viram sobra de setembro | prompt |
| RN-423 | Gastar mais que o máximo é aceito — é um fato — e o app sinaliza em tom neutro. A projeção do mês passa a usar o valor real | Lazer máximo R$ 250, gasto R$ 310: "Lazer passou R$ 60 do previsto" | D-UX-22 |
| RN-424 | Lançamento variável numa categoria sem faixa definida conta inteiro como gasto além do plano, e o app oferece criar a faixa | Primeiro lançamento em "manutenção": R$ 700 além do plano | modelagem |
| RN-425 | Em categoria elegível ao vale, o plano consome o vale primeiro. A parte em dinheiro do pior caso é `máx(0, máximo − vale disponível)` | Mercado R$ 800, vale disponível R$ 650: R$ 150 em dinheiro | D-UX-03 |
| RN-426 | Havendo mais de uma categoria elegível ao vale, o vale disponível é distribuído entre elas na ordem em que aparecem no plano, até acabar | Mercado R$ 600 e padaria R$ 120, vale R$ 650: mercado todo no vale, padaria R$ 50 no vale e R$ 70 em dinheiro | modelagem |
| RN-427 | Mudar uma faixa vale a partir de um mês informado | Transporte passa a R$ 200–300 a partir de outubro | modelagem |

## O plano do mês

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-430 | O plano de um mês reúne: renda esperada por moeda, vale disponível, fixos, variáveis pelo pior caso e parcelas de dívida que vencem no mês | Ver o exemplo completo em [indicators.md](indicators.md) | prompt |
| RN-431 | Na virada do mês, o plano seguinte é gerado a partir do que está vigente: fontes ativas, fixos ativos, faixas atuais e o calendário de parcelas. O usuário pode editar depois | Em 01/10 o plano de outubro já existe, com a parcela 1 da geladeira | modelagem |
| RN-432 | O app sugere, sem impor, incluir no plano uma **provisão de fora do padrão** igual à média mensal desses gastos nos últimos 12 meses | Média de R$ 146: "Quer reservar R$ 146 para gastos fora do padrão?" | D-UX-12 ⚑ validar |
| RN-433 | Meses futuros além do próximo só mostram o que já está comprometido — fixos vigentes e parcelas —, sem projetar variáveis | A tela de dívidas mostra as parcelas até o fim; não inventa mercado de março | modelagem |

## Fechamento

| ID | Regra | Exemplo ou teste | Origem |
|---|---|---|---|
| RN-440 | O fechamento é o retrato imutável de um mês encerrado: renda, blocos, indicadores, remanejamentos e comparação com o mês anterior | O fechamento de setembro não muda se uma faixa for alterada em outubro | prompt |
| RN-441 | Lançamento tardio num mês fechado gera uma **revisão** do fechamento; a versão anterior é preservada e a diferença fica visível | Setembro rev. 2: "+ R$ 42,00 em transporte, lançado em 03/10" | modelagem |
| RN-442 | Um mês só pode ser fechado depois que ele termina, no fuso de negócio | Fechar setembro em 28/09 é rejeitado | modelagem |
| RN-443 | A falta de um mês fechado não vira dívida automática nem é descontada do mês seguinte por conta própria: ela é informada, e o que fazer é decisão do usuário | Setembro fechou com falta de R$ 142: outubro nasce normal, com a informação em destaque no fechamento | modelagem ⚑ validar |
