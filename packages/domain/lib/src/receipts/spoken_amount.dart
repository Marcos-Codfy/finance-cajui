import 'package:domain/src/money/money.dart';

/// O valor de um gasto dito em voz alta (RN-1091): "gastei 40 no mercado",
/// "paguei 120 de luz no dia 5", "40 reais e 50 centavos".
///
/// A frase falada tem outros números além do valor — o dia, a hora, as
/// parcelas —, e o primeiro número da frase nem sempre é o valor: "dia 5
/// paguei 120" não é R$ 5,00. A ordem de confiança é:
///
/// 1. o número colado a "R$" ou seguido de "reais";
/// 2. senão, o primeiro número que não seja dia, hora ou data;
/// 3. frase com parcela ("2x", "3 vezes", "parcelado") não tem valor
///    seguro — é o total ou a parcela? —, e volta `null`: a conferência
///    pergunta, que é melhor do que lançar o número errado já preenchido.
abstract final class SpokenAmount {
  /// O valor dito em [text], ou `null` quando não há um valor seguro.
  static Money? of(String text) {
    final lower = text.toLowerCase();
    if (_installments.hasMatch(lower)) return null;
    final withCents = _reaisAndCents.firstMatch(lower);
    if (withCents != null) {
      final reais = _cents(withCents.group(1)!);
      return Money.fromCents(reais + int.parse(withCents.group(2)!));
    }
    final labeled = _labeled.firstMatch(lower);
    if (labeled != null) {
      return Money.fromCents(_cents(labeled.group(1) ?? labeled.group(2)!));
    }
    for (final match in _number.allMatches(lower)) {
      if (_isTimeOrDate(lower, match)) continue;
      return Money.fromCents(_cents(match.group(0)!));
    }
    return null;
  }

  /// Um número: "1.250,50", "1.200", "8,50", "8.50", "40".
  static const _num = r'\d{1,3}(?:\.\d{3})+(?:,\d{1,2})?|\d+(?:[.,]\d{1,2})?';

  static final _number = RegExp('(?:$_num)(?![\\d.,]*\\d)');

  /// "R$ 40" ou "40 reais".
  static final _labeled = RegExp(
    'r\\\$\\s*($_num)|($_num)\\s*(?:reais|real)\\b',
  );

  /// "40 reais e 50 centavos".
  static final _reaisAndCents = RegExp(
    '($_num)\\s*(?:reais|real)\\s*e\\s*(\\d{1,2})\\s*centavos?',
  );

  static final _installments = RegExp(r'\b\d+\s*(?:x|vezes)\b|parcel');

  /// O que, antes de um número, diz que ele é dia, hora ou o fim de uma
  /// data: "dia 5", "às 10", "11/10". A fronteira é o espaço, e não `\b`,
  /// que não reconhece o "à".
  static final _timeWord = RegExp(
    r'(?:(?:^|\s)(?:dia|às|as|das|ate|até)\s*|/|\d[h:])$',
  );

  /// O que, logo depois de um número, diz que ele é hora ou data.
  static final _timeTail = RegExp(r'^\s*(?:h\b|hs\b|horas?\b|:|/|º|°)');

  static bool _isTimeOrDate(String text, RegExpMatch match) =>
      _timeWord.hasMatch(text.substring(0, match.start)) ||
      _timeTail.hasMatch(text.substring(match.end));

  /// [number] em centavos: vírgula é decimal; ponto é milhar quando separa
  /// três dígitos, e decimal quando separa dois ("8.50").
  static int _cents(String number) {
    if (number.contains(',')) {
      final parts = number.replaceAll('.', '').split(',');
      return int.parse(parts[0]) * 100 + int.parse(parts[1].padRight(2, '0'));
    }
    final decimal = RegExp(r'\.(\d{1,2})$').firstMatch(number);
    if (decimal != null) {
      final reais = number.substring(0, decimal.start).replaceAll('.', '');
      return int.parse(reais) * 100 +
          int.parse(decimal.group(1)!.padRight(2, '0'));
    }
    return int.parse(number.replaceAll('.', '')) * 100;
  }
}
