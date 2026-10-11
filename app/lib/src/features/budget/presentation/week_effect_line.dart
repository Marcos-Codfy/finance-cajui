import 'package:cajui/src/features/home/application/home_view.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O efeito da compra no "pode gastar esta semana", **antes** de lançar:
/// "Resta na semana: R$ 153,37 → R$ 144,87" (UC-ENTRY-01).
///
/// Só aparece quando a compra mexe mesmo no limite: há plano, a categoria é
/// do dia a dia, a data cai na semana em curso e a compra não é parcelada —
/// a parcela vem da dívida (RN-312). O limite da planilha conta o que o vale
/// cobre, então o vale também conta aqui (RN-1018).
class WeekEffectLine extends ConsumerWidget {
  /// Cria a linha para o rascunho [draft].
  const new({required this.draft, super.key});

  /// O que a pessoa já preencheu.
  final EntryDraft draft;

  Money get _total =>
      draft.lines.fold(Money.zero, (sum, line) => sum + line.amount);

  bool _affects(HomeView view) {
    final day = draft.occurredOn;
    // Sem data escolhida não há semana a que o gasto pertença (RN-748).
    if (day == null) return false;
    return view.hasPlan &&
        // Na correção, o "antes" já conta a versão antiga: a linha diria um
        // efeito que não existe.
        draft.correctionOf == null &&
        draft.category?.block == Block.variable &&
        _total.isPositive &&
        draft.installmentCount == 1 &&
        view.week.contains(day);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(homeViewProvider);
    if (view == null || !_affects(view)) return const SizedBox.shrink();
    final theme = CajuiTheme.of(context);
    final before = view.week;
    final after = before.withSpending(_total);
    String brl(Money amount) => BrlFormatter.format(amount.cents);
    return Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.md),
      child: Text(
        after.over.isPositive
            ? 'Com esta compra, a semana passa ${brl(after.over)} do limite.'
            : 'Resta na semana: ${brl(before.left)} → ${brl(after.left)}',
        textAlign: TextAlign.center,
        style: theme.typography.label.copyWith(color: theme.colors.text.muted),
      ),
    );
  }
}
