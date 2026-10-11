import 'package:design_system/src/format/brl_formatter.dart';
import 'package:flutter/foundation.dart';

/// Uma barra do gráfico de mês a mês: um mês e o que sobrou ou faltou nele.
@immutable
class CajuiChartBar {
  /// Cria a barra do mês [title], com [cents] de saldo.
  const new({
    required this.label,
    required this.title,
    required this.cents,
    required this.note,
  });

  /// O nome curto, embaixo da barra: "mar".
  final String label;

  /// O nome inteiro, no destaque e no leitor de tela: "Março".
  final String title;

  /// O saldo do mês, em centavos. Negativo quando faltou.
  final int cents;

  /// A palavra antes do valor, no tom do guia de voz: "Sobrou", "Faltou",
  /// "Fechou no zero". É ela, e não a cor, que diz o sentido do número.
  final String note;

  /// O que o leitor de tela diz da barra: "Março: sobrou R$ 312,00".
  String get spoken =>
      '$title: ${note.toLowerCase()} ${BrlFormatter.format(cents.abs())}';

  @override
  bool operator ==(Object other) =>
      other is CajuiChartBar &&
      other.label == label &&
      other.title == title &&
      other.cents == cents &&
      other.note == note;

  @override
  int get hashCode => Object.hash(label, title, cents, note);
}
