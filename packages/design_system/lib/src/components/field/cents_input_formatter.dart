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
  static int parse(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? 0 : int.parse(digits);
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > maxDigits) return oldValue;
    final text = BrlFormatter.number(digits.isEmpty ? 0 : int.parse(digits));
    return TextEditingValue(
      text: text,
      // O cursor fica sempre no fim: é por lá que os dígitos entram.
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
