import 'package:design_system/design_system.dart';
import 'package:gallery/src/pages/screens/home/home_numbers.dart';

/// O extrato de outubro conferido com a Juju (RN-1100 a RN-1120), com as
/// frases que o domínio monta (`StatementWords`) já preenchidas.
///
/// As contas fecham entre si: 74 movimentações lidas são 56 gastos, 2
/// entradas — o salário e o freela, o que entra no Início —, 3 pagamentos
/// de fatura, 8 transferências entre contas, 4 que já estavam no Cajui e o
/// Pix em dúvida. Entram em "Pode lançar" os gastos certos e as entradas:
/// 57 de saída, 58 depois de a categoria em dúvida ser respondida.
///
/// Os valores passam pelo formatador, como os do domínio: o espaço depois
/// do "R$" não quebra linha, e o "R$" nunca fica sozinho no fim do balão.
abstract final class StatementSample {
  static String _brl(int cents) => BrlFormatter.format(cents);

  /// O arquivo compartilhado do app do banco.
  static const file = 'Extrato de outubro.pdf · 7 páginas';

  /// A leitura, uma página por vez (RN-1102).
  static const reading = 'Lendo a página 3 de 7…';

  /// O resumo que abre a conversa (RN-1112).
  static String get summary =>
      'Li 74 movimentações de 1 a 31 de outubro. 56 gastos, '
      '${_brl(196840)}; 2 entradas, ${_brl(HomeNumbers.income)}. 3 '
      'pagamentos de fatura e 8 transferências entre contas não contam. 4 já '
      'estavam no Cajui. 2 ficaram em dúvida: pergunto depois dos blocos.';

  /// O maior bloco de categoria (RN-1113).
  static String get market =>
      'Mercado — 12 compras, ${_brl(124000)}: Assaí, Atacadão, Pão de '
      'Açúcar e mais 9. Confere?';

  /// As compras do bloco Mercado, que somam R$ 1.240,00.
  static const List<(String, String, int)> _marketLines = [
    ('02/10', 'Assaí', 31240),
    ('04/10', 'Atacadão', 26890),
    ('06/10', 'Pão de Açúcar', 9630),
    ('08/10', 'Sacolão Ipê', 4280),
    ('10/10', 'Mercado do Bairro', 5860),
    ('13/10', 'Carrefour', 12470),
    ('15/10', 'Hortifruti Cerrado', 3750),
    ('18/10', 'Mercadinho São José', 2990),
    ('20/10', 'Dia', 6420),
    ('23/10', 'Empório Pequi', 8140),
    ('27/10', 'Feira da Asa Sul', 4500),
    ('30/10', 'Supermercado Buriti', 7830),
  ];

  /// As linhas do bloco, como a lista curta da fala: "05/10 · Assaí".
  static List<CajuiPromptRow> get marketRows => [
    for (final (day, name, cents) in _marketLines)
      (label: '$day · $name', value: _brl(cents)),
  ];

  /// A dúvida de tipo: o nome de verdade só aparece no celular (RN-1106).
  static String get kindQuestion =>
      'Pix para João P Silva, ${_brl(15000)}, em 12/10. O que foi?';

  /// As respostas de tipo (RN-1114).
  static const List<String> kinds = [
    expense,
    'Alguém da casa',
    'Conta minha',
    'Não lançar',
  ];

  /// A resposta que faz o Pix virar gasto, e entrar no lote.
  static const expense = 'É um gasto';

  /// A dúvida de categoria.
  static String get categoryQuestion =>
      'Padaria Boa Vista, ${_brl(1850)}, em 05/10. Qual é a categoria?';

  /// As quatro categorias mais prováveis e "Outra" (RN-1114).
  static const List<String> categories = [
    'Padaria',
    'Mercado',
    'Restaurante e lanche',
    'Farmácia',
    'Outra',
  ];

  /// Quantos entram antes de responder a dúvida de categoria.
  static const sureCount = 57;

  /// O botão que grava o lote (RN-1115).
  static String launch(int count) => 'Pode lançar ($count)';

  /// Depois de gravar (RN-1118).
  static String done(int count) =>
      'Lancei $count lançamentos. Se algo não estiver certo, dá para '
      'desfazer tudo de uma vez.';

  /// Depois de desfazer o lote inteiro (RN-1119).
  static String undone(int count) => 'Desfiz os $count lançamentos.';

  /// "Conferir depois": a leitura fica guardada, e nada é gravado.
  static const later =
      'Guardei esta leitura em Para conferir. Nada foi lançado ainda.';
}
