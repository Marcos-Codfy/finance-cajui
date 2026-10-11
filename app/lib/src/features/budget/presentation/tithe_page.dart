import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/budget/application/plan_service.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O dízimo: um percentual da renda em dinheiro, que pode ser zero (regra 5
/// da planilha). Os valores mais comuns ficam em fichas, a um toque.
class TithePage extends ConsumerWidget {
  /// Cria a tela.
  const new({super.key});

  /// Abre a tela.
  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push<void>(CajuiPageRoute(builder: (_) => const TithePage()));

  /// As opções, em centésimos de por cento: não pago, 5% e 10%.
  static const options = [0, 500, 1000];

  /// O nome de [basisPoints] na tela: "Não pago", "10%", "12,5%".
  static String labelOf(int basisPoints) {
    if (basisPoints == 0) return 'Não pago';
    if (basisPoints % 100 == 0) return '${basisPoints ~/ 100}%';
    return '${(basisPoints / 100).toString().replaceAll('.', ',')}%';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(financesProvider)?.plan ?? BudgetPlan.empty;
    final theme = CajuiTheme.of(context);
    return CajuiScreen(
      title: 'Dízimo',
      onBack: Navigator.of(context).pop,
      children: [
        Text(
          'O dízimo sai da renda em dinheiro, antes do dia a dia. O vale não '
          'entra na conta.',
          style: theme.typography.body.copyWith(color: theme.colors.text.muted),
        ),
        const SizedBox(height: CajuiSpacing.lg),
        Wrap(
          spacing: CajuiSpacing.sm,
          runSpacing: CajuiSpacing.sm,
          children: [
            for (final basisPoints in options)
              CajuiChip(
                label: labelOf(basisPoints),
                selected: plan.titheBasisPoints == basisPoints,
                onSelected: (_) => _choose(context, ref, plan, basisPoints),
              ),
          ],
        ),
      ],
    );
  }

  static Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    BudgetPlan plan,
    int basisPoints,
  ) async {
    final navigator = Navigator.of(context);
    await ref
        .read(planServiceProvider)
        .define(plan.copyWith(titheBasisPoints: basisPoints));
    navigator.pop();
  }
}
