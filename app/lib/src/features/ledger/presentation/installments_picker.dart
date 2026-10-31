import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';

/// As opções de "em quantas vezes" a compra foi feita no cartão.
///
/// Vai até doze: mais que isso é raro, e lista comprida esconde o "à vista",
/// que é o caso comum. Quem abre a escolha é o `LedgerCoordinator`.
abstract final class InstallmentsPicker {
  static const _max = 12;

  /// As quantidades oferecidas, de 1 a doze.
  static final List<int> options = [
    for (var count = 1; count <= _max; count++) count,
  ];

  /// O texto de [count] vezes para uma compra de [total].
  static String label(int count, Money total) {
    if (count == 1) return 'À vista';
    if (!total.isPositive) return '${count}x';
    final each = total.split(count).first;
    return '${count}x de ${BrlFormatter.format(each.cents)}';
  }
}
