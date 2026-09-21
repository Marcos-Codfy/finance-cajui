import 'package:cajui/src/features/ledger/presentation/option_picker_page.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// Em quantas vezes a compra foi feita no cartão.
///
/// Vai até doze: mais que isso é raro, e lista comprida esconde o "à vista",
/// que é o caso comum.
abstract final class InstallmentsPicker {
  static const _max = 12;

  /// Abre a escolha para uma compra de [total], com [selected] marcado.
  static Future<int?> open(
    BuildContext context, {
    required Money total,
    required int selected,
  }) {
    return OptionPickerPage.open<int>(
      context,
      title: 'Em quantas vezes',
      options: [for (var count = 1; count <= _max; count++) count],
      labelOf: (count) => _label(count, total),
      selected: selected,
    );
  }

  static String _label(int count, Money total) {
    if (count == 1) return 'À vista';
    if (!total.isPositive) return '${count}x';
    final each = total.split(count).first;
    return '${count}x de ${BrlFormatter.format(each.cents)}';
  }
}
