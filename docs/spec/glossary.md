# Glossário

Vocabulário único do projeto. A coluna **Código** é o identificador em inglês usado em classes, arquivos e rotas; a coluna **Na tela** é como o termo aparece para o usuário, seguindo o [guia de voz](../brand/voice-and-tone.md). Um conceito tem um nome só: se a palavra não está aqui, ela não entra na especificação nem no código.

## Dinheiro

| Termo | Código | Na tela | Definição |
|---|---|---|---|
| Valor monetário | `Money` | R$ 1.284,50 | Quantia em **centavos inteiros**, sempre em reais. Nunca ponto flutuante |
| Moeda | `Tender` | — | De que é feito o valor: `cash` (dinheiro) ou `mealVoucher` (vale). Não é câmbio |
| Dinheiro | `Tender.cash` | dinheiro | Renda que cai em conta e paga qualquer coisa |
| Vale alimentação | `Tender.mealVoucher` | vale | Crédito que só paga despesa de alimentação. Acumula de um mês para o outro |
| Fonte de renda | `IncomeSource` | renda | Origem recorrente de entrada: salário, segundo salário, o crédito do vale |
| Recebimento | `IncomeReceipt` | entrada | O crédito efetivo de uma fonte num mês |

## Lançamento

| Termo | Código | Na tela | Definição |
|---|---|---|---|
| Lançamento | `Entry` | lançamento | O registro de **o que foi comprado**: descrição, valor, data, categoria, bloco |
| Linha de pagamento | `PaymentLine` | pago com | A parte de um lançamento paga por uma forma de pagamento. Um lançamento tem uma ou mais; a soma é igual ao valor |
| Forma de pagamento | `PaymentMethod` | por onde foi pago | Dinheiro vivo, Pix, débito, cartão de crédito, vale, boleto |
| Categoria | `Category` | categoria | A natureza do gasto: mercado, aluguel, ônibus |
| Grupo | `CategoryGroup` | — | Agrupamento de categorias para os indicadores: moradia, transporte, alimentação, assinaturas, saúde, lazer, outros |
| Data da compra | `occurredOn` | data | O dia em que a compra aconteceu |
| Mês de competência | `BudgetMonth` | mês | O mês em cujo orçamento um valor conta |
| Reconhecimento | `recognition` | — | A regra que decide em que mês um valor conta. Varia com a forma de pagamento e o parcelamento |
| Fora do padrão | `isExceptional` | fora do padrão | Marca de gasto que não se repete todo mês. É atributo do lançamento, não categoria |
| Estorno | `Reversal` | estorno | Lançamento que anula outro, no todo ou em parte. O original não é apagado |

## Blocos e orçamento

| Termo | Código | Na tela | Definição |
|---|---|---|---|
| Bloco | `Block` | bloco | Uma das três partições de despesa: `fixed`, `variable`, `debt` |
| Fixo | `FixedExpense` | fixo | Despesa de mesmo valor todo mês, com dia de vencimento |
| Variável | `VariableBudget` | variável | Categoria com faixa mínima–máxima |
| Faixa | `AmountRange` | entre R$ X e R$ Y | O mínimo e o máximo esperados de um variável |
| Pior caso | `worstCase` | — | O máximo da faixa. É o valor que entra no orçamento |
| Orçamento do mês | `MonthPlan` | plano do mês | Rendas esperadas, fixos, variáveis pelo pior caso e parcelas do mês |
| Remanejamento | `Reallocation` | mover | Cobrir um bloco com folga de outro. Sempre ação explícita, sempre registrada |
| Fechamento | `MonthClose` | fechamento | O retrato imutável do mês encerrado |

## Cartão de crédito

| Termo | Código | Na tela | Definição |
|---|---|---|---|
| Cartão | `CreditCard` | cartão | Forma de pagamento com dia de fechamento e dia de vencimento |
| Ciclo | `StatementCycle` | ciclo | O intervalo entre dois fechamentos |
| Fatura | `CardStatement` | fatura | **Visão derivada**: a soma das linhas de pagamento daquele cartão naquele ciclo. Nunca é digitada, nunca é lançamento |
| Liquidação | `Settlement` | pagamento da fatura | O dinheiro que sai da conta para quitar a fatura. Não é despesa |
| Reserva da fatura | `statementReserve` | reservado para a fatura | Dinheiro do mês já contado como gasto, que precisa estar disponível quando a fatura vencer |
| Parcelamento | `InstallmentPlan` | parcelado em N× | Compra dividida em parcelas. Cada parcela conta no mês em que vence |
| Total comprometido | `committedTotal` | ainda comprometido | A soma das parcelas que faltam de um parcelamento |

## Dívidas

| Termo | Código | Na tela | Definição |
|---|---|---|---|
| Dívida | `Debt` | dívida | Obrigação com fim: saldo devedor, parcelas, juros opcionais |
| Saldo devedor | `outstandingBalance` | falta pagar | O que resta da dívida hoje |
| Parcela | `Installment` | parcela | O valor devido num mês |
| Quitação | `payoff` | quitada | O momento em que o saldo chega a zero |
| Previsão de quitação | `payoffForecast` | quita em | Estimativa do mês de quitação no ritmo atual. É projeção, e é dita como projeção |

## Indicadores

| Termo | Código | Na tela | Definição |
|---|---|---|---|
| Sobra | `surplus` | sobram R$ X | Resultado do mês em dinheiro, quando positivo |
| Falta | `shortfall` | faltam R$ X | Resultado do mês em dinheiro, quando negativo. Na tela nunca aparece como "déficit", "rombo" ou "no vermelho" |
| Comprometimento | `commitmentRatio` | X% da renda | Parte da renda em dinheiro já destinada a fixos e dívidas; também por grupo |
| Limite semanal | `weeklyLimit` | limite da semana | Quanto de variável em dinheiro cabe na semana de calendário, recalculado a cada semana |
| Resta na semana | `weekRemaining` | sobram R$ X até domingo | Limite semanal menos o já gasto na semana. É o número principal do painel |
| Custo de vida por dia | `dailyCost` | R$ X por dia | Despesas do mês divididas pelos dias do mês |
| Ajuste necessário | `requiredAdjustment` | falta ajustar R$ X | Quanto precisa sair do plano para o mês fechar |
| Folga ajustável | `adjustableSlack` | dá para ajustar até R$ X | Quanto os variáveis ainda podem encolher sem passar do mínimo da faixa |

## Captura e IA

| Termo | Código | Na tela | Definição |
|---|---|---|---|
| Compartilhamento | `ShareIntake` | compartilhar com o Cajui | A chegada de imagem, PDF ou texto vindos de outro app Android |
| Comprovante | `Receipt` | comprovante | O arquivo original recebido, guardado como veio |
| Texto extraído | `extractedText` | — | O resultado do OCR local. É a única coisa que sai do aparelho rumo à IA |
| Proposta | `EntryProposal` | — | Os campos sugeridos para um lançamento, cada um com sua confiança |
| Confiança | `Confidence` | alta · média · baixa | A certeza da proposta para um campo, em três zonas |
| Pergunta de esclarecimento | `ClarificationQuestion` | — | A pergunta em português claro que o app faz quando a confiança é baixa |
| Regra aprendida | `LearnedRule` | vou lembrar | Associação estabelecimento → categoria criada por uma correção. Roda antes da IA |
| Classificador por regras | `RuleBasedClassifier` | — | O caminho determinístico que assume quando a IA está fora do ar |
| Redação de dados pessoais | `PiiRedaction` | — | Mascaramento de CPF, conta e chave Pix antes de qualquer envio à IA |
| Contexto do assistente | `AssistantContext` | — | Os resumos e agregados enviados ao chat. Nunca o banco inteiro |

## Infraestrutura de dados

| Termo | Código | Na tela | Definição |
|---|---|---|---|
| Evento | `DomainEvent` | — | Um fato imutável do log: lançamento criado, categoria corrigida, fatura liquidada |
| Log de eventos | `EventLog` | — | A sequência só de acréscimo que é a fonte da verdade |
| Snapshot | `MonthSnapshot` | — | O estado consolidado de um mês, para não reprocessar o log inteiro |
| Dispositivo pareado | `PairedDevice` | este aparelho | O aparelho cuja chave pública o servidor conhece |
