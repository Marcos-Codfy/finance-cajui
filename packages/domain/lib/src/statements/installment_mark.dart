import 'package:meta/meta.dart';

/// A parcela escrita numa linha de fatura: "LOJA X 03/10", "PARC 3/10"
/// (RN-1111).
///
/// A fatura do cartão traz, a cada mês, a parcela de compras feitas antes.
/// Ela não é um gasto novo como os outros: se a compra já está no Cajui em
/// várias vezes, o plano já conta a parcela; se não está, a pessoa decide
/// se a parcela entra como gasto do mês. Por isso a linha com parcela nunca
/// entra calada.
@immutable
final class InstallmentMark {
  const new _(this.number, this.total);

  /// Qual parcela é: a 3 de "3/10".
  final int number;

  /// De quantas: o 10 de "3/10".
  final int total;

  /// A parcela escrita em [line], ou `null`.
  ///
  /// O primeiro "dd/mm" da linha é a data da movimentação, e não conta. Um
  /// segundo "n/m" depois dele, com n ≤ m e m entre 2 e 48, é parcela; com
  /// "PARC" ou "PARCELA" antes, também o primeiro.
  static InstallmentMark? of(String line) {
    final upper = line.toUpperCase();
    final labeled = _labeled.firstMatch(upper);
    if (labeled != null) return _mark(labeled[1]!, labeled[2]!);
    final pairs = _pair.allMatches(upper).toList();
    final first = pairs.isEmpty ? null : pairs.first;
    final startsWithDate =
        first != null && upper.substring(0, first.start).trim().isEmpty;
    for (final pair in pairs.skip(startsWithDate ? 1 : 0)) {
      // A mesma data repetida ("05/10 COMPRA 05/10") é data, não parcela.
      if (startsWithDate && pair[0] == first[0]) continue;
      final mark = _mark(pair[1]!, pair[2]!);
      if (mark != null) return mark;
    }
    return null;
  }

  static InstallmentMark? _mark(String number, String of) {
    final (n, m) = (int.parse(number), int.parse(of));
    if (m < 2 || m > 48 || n < 1 || n > m) return null;
    return InstallmentMark._(n, m);
  }

  static final _labeled = RegExp(
    r'PARC(?:ELA)?\.?\s*(\d{1,2})\s*(?:/|DE)\s*(\d{1,2})',
  );

  static final _pair = RegExp(r'(?<![\d/])(\d{1,2})/(\d{1,2})(?![\d/])');
}
