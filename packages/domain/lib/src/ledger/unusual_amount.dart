import 'package:domain/src/ledger/entry.dart';
import 'package:domain/src/money/money.dart';
import 'package:meta/meta.dart';

/// Um valor muito acima do que a categoria costuma ter: o zero digitado a
/// mais, que transforma R$ 150,00 em R$ 1.500,00.
///
/// Não é recusa — compra grande existe —, é um "confere?" antes de gravar.
/// O normal da categoria é a **mediana** dos últimos lançamentos dela, e
/// não a média: uma compra grande do passado puxaria a média para cima e
/// esconderia justamente o próximo erro.
@immutable
final class UnusualAmount {
  const new _({required this.typical});

  /// Quantas vezes acima do normal o valor precisa estar para pedir
  /// confirmação. Dez é a vírgula no lugar errado.
  static const factor = 10;

  /// Com menos lançamentos que isto na categoria, não há "normal" ainda.
  static const minimumHistory = 3;

  /// Quantos lançamentos recentes da categoria entram na conta.
  static const sampleSize = 20;

  /// O normal da categoria: a mediana dos lançamentos recentes dela.
  final Money typical;

  /// O aviso para [amount] na categoria [categoryId], ou `null` quando o
  /// valor está dentro do normal ou ainda não há histórico para comparar.
  static UnusualAmount? check(
    Money amount, {
    required String categoryId,
    required Iterable<Entry> history,
  }) {
    final samples = [
      for (final entry in history)
        if (entry.categoryId == categoryId) entry,
    ]..sort((a, b) => b.occurredOn.compareTo(a.occurredOn));
    if (samples.length < minimumHistory) return null;
    final cents = [
      for (final entry in samples.take(sampleSize)) entry.amount.cents,
    ]..sort();
    final typical = Money.fromCents(cents[cents.length ~/ 2]);
    if (typical.isZero || amount < typical * factor) return null;
    return UnusualAmount._(typical: typical);
  }
}
