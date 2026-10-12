import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// Uma célula da planilha exportada, já com o tipo que o Excel entende: o
/// valor vira número com o formato de real, e a data vira data — quem abre o
/// arquivo pode somar e ordenar sem converter nada.
@immutable
sealed class XlsxCell {
  const new();
}

/// Texto. [bold] para os títulos.
final class XlsxText extends XlsxCell {
  /// Cria a célula com [text].
  const new(this.text, {this.bold = false});

  /// O texto.
  final String text;

  /// Se vai em negrito.
  final bool bold;
}

/// Dinheiro, em centavos, que a planilha mostra como "R$ 1.234,56".
final class XlsxMoney extends XlsxCell {
  /// Cria a célula com [amount]. [bold] para os totais.
  const new(this.amount, {this.bold = false});

  /// O valor.
  final Money amount;

  /// Se vai em negrito.
  final bool bold;
}

/// Uma data, que a planilha mostra como "03/10/2026".
final class XlsxDate extends XlsxCell {
  /// Cria a célula com [date].
  const new(this.date);

  /// A data.
  final LocalDate date;
}

/// Um número inteiro, como a quantidade de parcelas.
final class XlsxCount extends XlsxCell {
  /// Cria a célula com [value].
  const new(this.value);

  /// O número.
  final int value;
}

/// Um percentual inteiro, que a planilha mostra como "72%".
final class XlsxPercent extends XlsxCell {
  /// Cria a célula com [percent], de 0 a 100 (ou mais).
  const new(this.percent);

  /// O percentual.
  final int percent;
}

/// A célula vazia.
final class XlsxEmpty extends XlsxCell {
  /// Cria a célula vazia.
  const new();
}
