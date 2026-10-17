import 'package:design_system/src/format/brl_formatter.dart';
import 'package:flutter/services.dart';

/// Faz o campo de valor se comportar como o de um app de banco: os dígitos
/// entram pela direita e a vírgula não precisa ser digitada.
///
/// Digitar 1, 2, 3 mostra 0,01 → 0,12 → 1,23. O valor nunca passa por
/// `double`: o que sai daqui são centavos inteiros (RN-101).
class CentsInputFormatter extends TextInputFormatter {
  /// Cria o formatador. [maxDigits] limita o valor a R$ 9.999.999,99.
  const new({this.maxDigits = 9});

  /// Quantos dígitos o campo aceita, contando os centavos.
  final int maxDigits;

  /// Lê os centavos de um texto já formatado, como "1.284,50".
  static int parse(String text) =>
      terms(text).fold(0, (sum, cents) => sum + cents);

  /// Os valores somados em [text], em centavos: "35,00 + 12,00" são dois.
  /// A conta rápida do campo (17/10/2026) — rachar e somar sem calculadora.
  static List<int> terms(String text) => [
    for (final part in text.split('+'))
      if (_digits(part).isNotEmpty) int.parse(_digits(part)),
  ];

  static String _digits(String text) => text.replaceAll(RegExp(r'\D'), '');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final shrank = newValue.text.length < oldValue.text.length;
    var parts = newValue.text.split('+');
    // Apagar logo depois do "+" tira a soma vazia do fim: "35,00 + " volta
    // a ser "35,00", e não fica preso no operador.
    if (shrank &&
        parts.length > 1 &&
        _digits(parts.last).isEmpty &&
        oldValue.text.trimRight().endsWith('+')) {
      parts = parts.sublist(0, parts.length - 1);
    }
    final shown = <String>[];
    for (final (index, part) in parts.indexed) {
      final digits = _digits(part);
      if (digits.length > maxDigits) return oldValue;
      final cents = digits.isEmpty ? 0 : int.parse(digits);
      // Só o primeiro valor mostra 0,00; os somados começam vazios.
      shown.add(index > 0 && cents == 0 ? '' : BrlFormatter.number(cents));
    }
    final text = shown.join(' + ');
    return TextEditingValue(
      text: text,
      // O cursor fica sempre no fim: é por lá que os dígitos entram.
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
