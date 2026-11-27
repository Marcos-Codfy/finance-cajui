import 'package:design_system/src/components/chip/cajui_chip.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// Os nomes das páginas do carrossel, no lugar dos pontos: "Sobra",
/// "Renda", "Gastos". Os pontos diziam só que havia mais; o nome diz o
/// quê, e leva direto à página (27/11/2026, heurística de reconhecer em
/// vez de lembrar).
///
/// Quebra a linha quando os nomes não cabem, em vez de cortar.
class CoverFlowTabs extends StatelessWidget {
  /// Cria os nomes [labels], com [current] marcado.
  const new({
    required this.labels,
    required this.current,
    required this.onSelect,
    super.key,
  });

  /// O nome de cada página, na ordem delas.
  final List<String> labels;

  /// A página em que o carrossel assentou ou vai assentar.
  final int current;

  /// Leva o carrossel à página pedida.
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: CajuiSpacing.sm,
    runSpacing: CajuiSpacing.sm,
    children: [
      for (final (index, label) in labels.indexed)
        CajuiChip(
          label: label,
          selected: index == current,
          onSelected: (_) => onSelect(index),
        ),
    ],
  );
}
