/// Os assuntos da tela "Como o Cajui conta": um título e a explicação.
///
/// É texto, e não conta: os exemplos usam números redondos e inventados, e
/// quem faz as contas de verdade continua sendo o domínio.
typedef HelpTopic = ({String title, String text});

/// Os assuntos, na ordem em que a pessoa encontra os números no Painel.
const List<HelpTopic> helpTopics = [
  (
    title: 'Renda do mês',
    text:
        'Tudo que entra em dinheiro no mês: salários e outras entradas que '
        'você cadastra em Minhas contas. O vale alimentação não entra aqui.',
  ),
  (
    title: 'Gastos do mês',
    text:
        'O previsto para o mês inteiro, em dinheiro: contas fixas, '
        'assinaturas, parcelas, dízimo e o que a planilha reserva para o '
        'dia a dia, menos a parte do mercado que o vale alimentação paga. '
        'Por isso ele aparece cheio já no começo do mês.',
  ),
  (
    title: 'Sobra ou falta',
    text:
        'Renda do mês menos gastos do mês. Com renda de '
        r'R$ 3.000,00 e gastos de R$ 2.400,00, sobram R$ 600,00. '
        'Se os gastos passam da '
        'renda, o Painel mostra quanto falta para fechar.',
  ),
  (
    title: 'Já gasto (Lançamentos)',
    text:
        'O que você já lançou no mês, separado por moeda. É diferente de '
        '"Gastos do mês": aquele é o previsto, este é o que já saiu.',
  ),
  (
    title: 'Vale alimentação',
    text:
        'É outra moeda. Ele paga mercado e alimentação, tem saldo próprio e '
        'nunca se soma ao dinheiro. Compra dividida entre vale e Pix conta '
        'cada parte na sua moeda.',
  ),
  (
    title: 'Cartão de crédito',
    text:
        'Cartão é forma de pagamento, não despesa. A compra conta no gasto '
        'pelo que foi comprado (mercado, farmácia), e a fatura é só a soma '
        'do que foi comprado no cartão, para você saber quanto vai pagar.',
  ),
  (
    title: 'Sincronização',
    text:
        'O que você lança fica guardado no celular na hora e sobe para o '
        'servidor quando há conexão. O aviso no alto do Início diz quando '
        'foi a última vez; tocar nele sincroniza agora.',
  ),
];
