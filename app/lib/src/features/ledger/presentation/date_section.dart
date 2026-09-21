import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/ledger/presentation/option_picker_page.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// "Quando foi": hoje já vem marcado, ontem está a um toque, e qualquer
/// outro dia recente sai de uma lista.
///
/// A lista só tem dias que já passaram. Data futura não é lançamento, é
/// compromisso do plano (RN-206) — e o melhor jeito de não recusar uma data
/// é não oferecê-la.
class DateSection extends StatelessWidget {
  /// Cria a seção com [selected] marcado.
  const new({
    required this.selected,
    required this.today,
    required this.onChanged,
    super.key,
  });

  /// O dia escolhido.
  final LocalDate selected;

  /// O dia de hoje.
  final LocalDate today;

  /// Chamado com o dia escolhido.
  final ValueChanged<LocalDate> onChanged;

  /// Até onde a lista volta. Compra mais antiga que isso é rara, e lista
  /// maior fica ruim de rolar.
  static const _daysBack = 60;

  bool get _isOtherDay => selected != today && selected != today.addDays(-1);

  Future<void> _pickOther(BuildContext context) async {
    final picked = await OptionPickerPage.open<LocalDate>(
      context,
      title: 'Quando foi',
      options: [for (var i = 0; i <= _daysBack; i++) today.addDays(-i)],
      labelOf: (day) => DateLabels.day(day, today: today),
      selected: selected,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quando foi',
          style: theme.typography.label.copyWith(
            color: theme.colors.text.muted,
          ),
        ),
        const SizedBox(height: CajuiSpacing.sm),
        Wrap(
          spacing: CajuiSpacing.sm,
          runSpacing: CajuiSpacing.sm,
          children: [
            _chip('Hoje', today),
            _chip('Ontem', today.addDays(-1)),
            CajuiChip(
              label: _isOtherDay ? DateLabels.short(selected) : 'Outro dia',
              selected: _isOtherDay,
              onSelected: (_) => _pickOther(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chip(String label, LocalDate day) => CajuiChip(
    label: label,
    selected: selected == day,
    onSelected: (_) => onChanged(day),
  );
}
