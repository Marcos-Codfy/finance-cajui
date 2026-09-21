import 'package:domain/src/money/money.dart';

/// O dinheiro por escrito, no formato da casa: `R$ 1.284,50`.
///
/// Mora no domínio porque os **modelos de frase** moram aqui (RN-802): o
/// resumo que o app monta sem rede e o que o servidor monta precisam sair
/// iguais, letra por letra. O design system tem um formatador equivalente
/// para os componentes de tela; ele não depende do domínio de propósito, para
/// poder ser publicado sozinho.
abstract final class MoneyFormat {
  /// O espaço entre `R$` e o número, que não deixa a linha quebrar ali.
  static final String nbsp = String.fromCharCode(0xA0);

  /// O sinal de menos tipográfico, mais largo que o hífen.
  static final String minus = String.fromCharCode(0x2212);

  /// [amount] como `R$ 1.284,50`.
  static String brl(Money amount) {
    final sign = amount.isNegative ? minus : '';
    final cents = amount.cents.abs();
    final fraction = '${cents % 100}'.padLeft(2, '0');
    return '${sign}R\$$nbsp${_grouped(cents ~/ 100)},$fraction';
  }

  static String _grouped(int whole) {
    final digits = '$whole';
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
