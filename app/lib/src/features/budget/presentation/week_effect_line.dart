import 'package:cajui/src/features/budget/application/month_overview.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O efeito da compra no limite da semana, **antes** de lançar: "Resta na
/// semana: R$ 153,37 → R$ 144,87" (UC-ENTRY-01, D-UX-05).
///
/// Só aparece quando a compra mexe mesmo no limite: categoria variável, parte
/// paga em dinheiro, data dentro da semana em curso e plano com faixas. O que
/// foi pago no vale não conta aqui — é outra moeda (RN-111).
class WeekEffectLine extends ConsumerWidget {
  /// Cria a linha para o rascunho [draft].
  const new({required this.draft, super.key});

  /// O que a pessoa já preencheu.
  final EntryDraft draft;

  Money get _cashPart => draft.lines
      .where((line) => line.tender == Tender.cash)
      .fold(Money.zero, (sum, line) => sum + line.amount);

  bool _affects(MonthOverview overview) {
    final week = overview.week.week;
    final day = draft.occurredOn;
    return overview.plan.variables.isNotEmpty &&
        draft.category?.block == Block.variable &&
        _cashPart.isPositive &&
        !day.isBefore(week.start) &&
        !day.isAfter(week.end);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(monthOverviewProvider);
    if (overview == null || !_affects(overview)) return const SizedBox.shrink();
    final theme = CajuiTheme.of(context);
    final before = overview.week.remaining;
    final after = before - _cashPart;
    String brl(Money amount) => BrlFormatter.format(amount.cents);
    return Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.md),
      child: Text(
        after.isNegative
            ? 'Com esta compra, a semana passa ${brl(-after)} do limite.'
            : 'Resta na semana: ${brl(before)} → ${brl(after)}',
        textAlign: TextAlign.center,
        style: theme.typography.label.copyWith(color: theme.colors.text.muted),
      ),
    );
  }
}
