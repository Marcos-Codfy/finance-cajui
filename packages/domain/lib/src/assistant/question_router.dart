import 'package:domain/src/assistant/question_intent.dart';

/// Lê a pergunta e diz se o próprio Cajui a responde (RN-960).
///
/// É de propósito uma coisa simples — gatilhos de texto, sem modelo e sem
/// rede. Errar para [QuestionIntent.unknown] não custa nada: a pergunta
/// segue para a IA, como sempre seguiu. Errar para o lado contrário custaria
/// uma resposta fora do assunto, então os gatilhos são específicos, e a
/// ordem vai do mais restrito ao mais geral.
abstract final class QuestionRouter {
  /// A intenção de [question], ou [QuestionIntent.unknown].
  static QuestionIntent of(String question) {
    final text = normalize(question);
    for (final (intent, triggers) in _triggers) {
      for (final trigger in triggers) {
        if (text.contains(trigger)) return intent;
      }
    }
    return QuestionIntent.unknown;
  }

  /// O texto em caixa baixa, sem acento e sem espaço sobrando.
  ///
  /// Quem pergunta no celular escreve com pressa: "quanto da pra gastar" tem
  /// de valer tanto quanto "Quanto dá para gastar?".
  static String normalize(String text) {
    final buffer = StringBuffer();
    for (final rune in text.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_accents[char] ?? char);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static const _accents = {
    'á': 'a', 'à': 'a', 'ã': 'a', 'â': 'a', 'ä': 'a', //
    'é': 'e', 'ê': 'e', 'è': 'e', 'ë': 'e',
    'í': 'i', 'î': 'i', 'ì': 'i', 'ï': 'i',
    'ó': 'o', 'ô': 'o', 'õ': 'o', 'ò': 'o', 'ö': 'o',
    'ú': 'u', 'û': 'u', 'ù': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n',
  };

  /// Gatilho por intenção, do mais restrito ao mais geral. A primeira que
  /// casar vence, então "quanto gastei hoje" não pode cair em "quanto
  /// gastei".
  static const List<(QuestionIntent, List<String>)> _triggers = [
    (QuestionIntent.today, ['hoje', 'no dia de hoje', 'resumo do dia']),
    (
      QuestionIntent.voucherBalance,
      [
        'vale alimentacao',
        'do vale',
        'no vale',
        'meu vale',
        'saldo do vale',
        'vale refeicao',
      ],
    ),
    (
      QuestionIntent.cardBill,
      ['fatura', 'cartao de credito', 'do cartao', 'no cartao', 'meu cartao'],
    ),
    (
      QuestionIntent.debts,
      [
        'divida',
        'dividas',
        'quanto devo',
        'estou devendo',
        'quitar',
        'parcela que falta',
      ],
    ),
    (
      QuestionIntent.weekLimit,
      [
        'nesta semana',
        'desta semana',
        'na semana',
        'da semana',
        'esta semana',
        'semanal',
        'posso gastar',
        'da pra gastar',
        'da para gastar',
      ],
    ),
    (
      QuestionIntent.whereMoneyWent,
      [
        'para onde foi',
        'pra onde foi',
        'onde foi o dinheiro',
        'onde gastei',
        'com o que gastei',
        'no que gastei',
        'maiores gastos',
        'maior gasto',
        'por categoria',
        'em que gastei',
      ],
    ),
    (
      QuestionIntent.monthClosing,
      [
        'fechando',
        'fechar o mes',
        'fecha o mes',
        'sobra',
        'resultado do mes',
        'como esta o mes',
        'situacao do mes',
        'saldo do mes',
      ],
    ),
  ];
}
