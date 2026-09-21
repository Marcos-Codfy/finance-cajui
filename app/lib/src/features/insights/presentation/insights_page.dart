import 'package:cajui/src/features/insights/application/insights.dart';
import 'package:cajui/src/features/insights/presentation/insight_period.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Os resumos do dia, da semana e do mês.
///
/// É texto, e não gráfico: cada frase já é a leitura do número — o que
/// aconteceu e o que dá para fazer —, no tom do guia de voz.
class InsightsPage extends ConsumerStatefulWidget {
  /// Cria a tela de resumos.
  const new({super.key});

  /// Abre a tela.
  static Future<void> open(BuildContext context) {
    return Navigator.of(context)
        .push<void>(CajuiPageRoute(builder: (_) => const InsightsPage()));
  }

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  InsightPeriod _period = InsightPeriod.day;

  @override
  Widget build(BuildContext context) {
    final insights = ref.watch(insightsProvider);
    return CajuiScreen(
      title: 'Resumos',
      onBack: Navigator.of(context).pop,
      children: [
        Wrap(
          spacing: CajuiSpacing.sm,
          children: [
            for (final period in InsightPeriod.values)
              CajuiChip(
                label: period.label,
                selected: period == _period,
                onSelected: (_) => setState(() => _period = period),
              ),
          ],
        ),
        const SizedBox(height: CajuiSpacing.xl),
        if (insights != null) ..._period.sections(insights).map(_section),
      ],
    );
  }

  Widget _section((String? title, List<String> lines) section) {
    final theme = CajuiTheme.of(context);
    final (title, lines) = section;
    return Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.xl),
      child: CajuiCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Semantics(
                header: true,
                child: Text(title, style: theme.typography.title),
              ),
              const SizedBox(height: CajuiSpacing.md),
            ],
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: CajuiSpacing.sm),
                child: Text(line, style: theme.typography.body),
              ),
          ],
        ),
      ),
    );
  }
}
