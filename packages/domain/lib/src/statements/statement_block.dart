import 'package:domain/src/money/money.dart';
import 'package:meta/meta.dart';

/// Um bloco da conferência (RN-1113): as compras certas de uma categoria,
/// para a pessoa conferir de uma vez.
///
/// Dinheiro e vale vêm separados: são moedas diferentes, e nunca se somam
/// num número só (RN-111).
@immutable
final class StatementBlock {
  /// Cria o bloco.
  const new({
    required this.categoryId,
    required this.lines,
    required this.cash,
    required this.voucher,
  });

  /// A categoria do bloco.
  final String categoryId;

  /// As linhas do bloco, pelo índice na lista lida, da maior para a menor.
  final List<int> lines;

  /// Quanto saiu em dinheiro.
  final Money cash;

  /// Quanto saiu no vale.
  final Money voucher;
}
