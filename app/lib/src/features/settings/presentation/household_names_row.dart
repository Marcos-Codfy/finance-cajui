import 'package:cajui/src/core/navigation/coordinator_access.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:cajui/src/features/settings/presentation/settings_coordinator.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A linha de Ajustes que abre os nomes da casa (RN-1070).
///
/// Diz em uma frase o que a lista muda. Fica num arquivo só dela, como a
/// das notificações: os Ajustes vão mudar de lugar, e ela vai junto. Na
/// consulta pela web não aparece — a web só lê (RN-906).
class HouseholdNamesRow extends ConsumerWidget {
  /// Cria a linha.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(ledgerUplinkProvider).isPaired) {
      return const SizedBox.shrink();
    }
    final count =
        ref.watch(ledgerProvider).value?.householdNames.names.length ?? 0;
    return CajuiListRow(
      title: 'Nomes da casa',
      subtitle: switch (count) {
        0 => 'Para Pix entre contas da casa não contar como gasto',
        1 => '1 nome: Pix entre contas da casa não conta como gasto',
        _ => '$count nomes: Pix entre contas da casa não conta como gasto',
      },
      trailing: const CajuiIcon(CajuiIconData.chevronRight),
      semanticLabel: 'Nomes da casa, abrir',
      onPressed: () =>
          context.coordinator(settingsCoordinatorProvider).openHouseholdNames(),
    );
  }
}
