import 'package:domain/src/ledger/block.dart';
import 'package:domain/src/money/money.dart';
import 'package:meta/meta.dart';

/// Uma categoria do mês: o previsto em "Minhas contas", o gasto de verdade
/// e o que conta, que é o maior dos dois — o "use o maior" da planilha.
@immutable
final class BudgetItem {
  /// Cria o item.
  const new({
    required this.categoryId,
    required this.block,
    required this.planned,
    required this.spent,
  });

  /// A categoria.
  final String categoryId;

  /// O grupo do mês em que ela entra.
  final Block block;

  /// O previsto, somando as linhas da categoria.
  final Money planned;

  /// O gasto de verdade, nas duas moedas.
  final Money spent;

  /// O que conta no mês: o maior entre o previsto e o gasto. Enquanto o mês
  /// corre, a conta nunca fica abaixo do que se espera gastar.
  Money get counted => spent > planned ? spent : planned;

  /// Quanto ainda cabe no previsto; zero quando o gasto já passou.
  Money get leftInPlan => (planned - spent).orZeroIfNegative;
}
