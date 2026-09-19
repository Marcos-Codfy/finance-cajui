# O problema

## De onde o app parte

O Cajui substitui uma planilha que **já existe e funciona**. Ela resolve o orçamento do domicílio com uma lógica própria, amadurecida no uso; o app não inventa método novo — reproduz essa lógica, elimina a digitação e conserta o ponto em que toda planilha quebra.

## A lógica da planilha

### Receitas: duas moedas

| Moeda | O que é | O que pode pagar |
|---|---|---|
| **Dinheiro** | Salário e qualquer renda que cai em conta; o domicílio pode ter mais de uma fonte | Tudo |
| **Vale alimentação** | Crédito mensal em cartão próprio | Só despesa de alimentação |

O vale **não é dinheiro**. Somar as duas rendas num total único produz um número que não existe: R$ 300 de vale sobrando não pagam R$ 300 de conta de luz. O app trata o vale como moeda separada em todo lugar — saldo, orçamento, indicadores — e nunca exibe um "saldo total" que some as duas (D-UX-03).

### Despesas: três blocos

| Bloco | Natureza | Como entra no orçamento |
|---|---|---|
| **Fixos** | Mesmo valor todo mês: aluguel, internet, assinaturas | Pelo valor conhecido |
| **Variáveis** | Mudam todo mês, dentro de uma faixa mínima–máxima: mercado, transporte, lazer | Pelo **pior caso** (o máximo da faixa). Mês bom vira sobra |
| **Dívidas** | Parcelas com fim: têm saldo devedor, número de parcelas e, às vezes, juros | Pela parcela do mês |

Orçar o variável pelo máximo é o que torna a planilha confiável: o plano já nasce pessimista, e a realidade só pode surpreender para melhor.

### Indicadores

A planilha responde, todo mês, a seis perguntas:

1. Quanto entra em dinheiro e quanto entra em vale?
2. O mês fecha com **sobra** ou com **falta**?
3. Quanto da renda está **comprometido** — no total, e com moradia, transporte, assinaturas e dívidas?
4. Quanto posso gastar de variável **por semana**?
5. Quanto custa viver **por dia**?
6. Se o mês não fecha, **quanto falta ajustar**?

## Onde a planilha quebra

### O cartão de crédito

Numa planilha comum, "Fatura do cartão — R$ 1.240" aparece como uma linha de despesa. Isso está errado de três maneiras:

- **Esconde o que foi comprado.** Os R$ 1.240 são mercado, farmácia, streaming e uma parcela de geladeira. Na linha única, tudo isso some dos blocos — e os indicadores de comprometimento passam a mentir.
- **Conta duas vezes ou nenhuma.** Quem lança a compra *e* a fatura conta em dobro; quem lança só a fatura perde a categoria.
- **Desloca o gasto no tempo.** A compra de hoje só "aparece" no mês seguinte, quando a fatura chega. É exatamente o desacoplamento entre comprar e pagar que leva a gastar mais (D-UX-05).

> **Cartão de crédito não é despesa. É forma de pagamento.**

Este é o requisito mais importante do produto. Todo lançamento registra duas coisas, separadas:

| | Pergunta | Exemplo |
|---|---|---|
| **O que foi comprado** | Descrição, valor, categoria, bloco | Mercado · R$ 186,40 · alimentação · variável |
| **Por onde foi pago** | Forma de pagamento | Cartão de crédito final 4821 |

A **fatura** é uma visão derivada: a soma do que foi pago com aquele cartão naquele ciclo. Ela nunca é digitada e nunca é uma linha de despesa. Pagar a fatura é uma **liquidação** — o dinheiro sai da conta para quitar o que já foi contado —, não um gasto novo.

### A digitação

Manter a planilha custa disciplina diária de digitar cada gasto. É a parte que falha primeiro num mês corrido, e mês corrido costuma ser mês apertado — justamente quando o registro mais importa.

### O silêncio

A planilha não avisa nada. Só mostra a situação para quem abre, e quem está no aperto tende a não abrir (Olafsson2025, Gladstone2021).

## O que o app faz a respeito

| Problema | Resposta do Cajui | Onde está especificado |
|---|---|---|
| Cartão como despesa | Lançamento separa compra de pagamento; fatura é visão derivada | [rules/credit-card.md](rules/credit-card.md) |
| Vale somado ao dinheiro | Duas moedas, nunca somadas | [rules/income-and-tenders.md](rules/income-and-tenders.md) |
| Digitação | Compartilhar o comprovante de qualquer app Android: OCR local, classificação proposta, confirmação em uma tela | [sharing-flow.md](sharing-flow.md) |
| Classificação errada em silêncio | Quando há dúvida, o app pergunta; a resposta vira exemplo | [rules/capture-and-classification.md](rules/capture-and-classification.md) |
| Silêncio | Retorno diário, semanal e mensal, em tom que não julga | [feedback.md](feedback.md) |
| Número sem explicação | Conversa com IA sobre os dados reais, que mostra de onde veio cada conta | [assistant.md](assistant.md) |
| Medo de abrir | O painel abre no que ainda dá para fazer, não no tamanho do problema | [rules/indicators.md](rules/indicators.md) |

## Fora do escopo

Dizer o que o app **não** é evita que ele cresça para os lados:

- **Sem integração bancária.** Nenhuma conexão com banco, Open Finance ou leitura de notificação. Os dados entram por compartilhamento ou digitação. Consequência: o app não conhece o saldo da conta — trabalha com orçamento, e todo número que depende de caixa é estimativa declarada como tal.
- **Sem investimentos.** Nem carteira, nem rentabilidade, nem recomendação de produto financeiro.
- **Um usuário só.** Sem contas múltiplas, convites, papéis ou compartilhamento. O domicílio pode ter várias fontes de renda; quem opera o app é uma pessoa.
- **Sem captura na web.** O navegador no desktop é modo consulta: painel, relatórios e conversa. Compartilhamento, OCR e câmera são do Android.
- **Uma moeda corrente.** Real brasileiro. "Duas moedas" neste documento significa dinheiro e vale, não câmbio.
