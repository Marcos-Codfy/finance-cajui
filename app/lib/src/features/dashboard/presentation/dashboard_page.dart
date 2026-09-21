import 'package:cajui/src/app/home_tab.dart';
import 'package:cajui/src/app/home_tab_controller.dart';
import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/budget/application/month_overview.dart';
import 'package:cajui/src/features/budget/presentation/plan_page.dart';
import 'package:cajui/src/features/dashboard/presentation/dashboard_blocks.dart';
import 'package:cajui/src/features/dashboard/presentation/dashboard_state.dart';
import 'package:cajui/src/features/insights/application/insights.dart';
import 'package:cajui/src/features/insights/presentation/insights_page.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O painel: a primeira tela. Responde uma pergunta antes de qualquer outra —
/// quanto dá para gastar nesta semana.
class DashboardPage extends ConsumerWidget {
  /// Cria o painel.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardStateProvider);
    return switch (state) {
      DashboardLoading() => const CajuiScreen(
        title: 'Painel',
        children: [
          CajuiSkeleton(height: 148),
          SizedBox(height: CajuiSpacing.lg),
          CajuiSkeleton(height: 112),
        ],
      ),
      DashboardFirstUse() => _firstUse(context),
      DashboardReady(:final overview) => _ready(context, ref, state, overview),
    };
  }

  Widget _firstUse(BuildContext context) => CajuiScreen(
    title: 'Painel',
    children: [
      CajuiEmptyState(
        illustration: const CajuiHeroFruit(),
        title: 'Seu mês começa aqui',
        message:
            'Com a renda e as contas fixas, o Cajui já diz quanto dá para '
            'gastar por semana. Leva uns cinco minutos.',
        action: CajuiNoticeAction(
          label: 'Começar',
          onPressed: () => PlanPage.open(context),
        ),
      ),
    ],
  );

  Widget _ready(
    BuildContext context,
    WidgetRef ref,
    DashboardReady state,
    MonthOverview overview,
  ) {
    final week = overview.week.week;
    final month = DateLabels.month(overview.plan.month).split(' ').first;
    return CajuiScreen(
      title: month[0].toUpperCase() + month.substring(1),
      overline: 'Semana de ${week.start.day} a ${week.end.day}',
      trailing: CajuiIconButton(
        icon: CajuiIconData.sliders,
        semanticLabel: 'Plano do mês',
        onPressed: () => PlanPage.open(context),
      ),
      footer: CajuiButton(
        label: 'Novo lançamento',
        icon: CajuiIconData.plus,
        expand: true,
        onPressed: () => EntryFormPage.open(context),
      ),
      children: [
        ..._notices(context, ref, state),
        ...DashboardBlocks.of(overview),
        _summaries(context, ref),
      ],
    );
  }

  /// O que precisa ser dito antes dos números: renda que falta e
  /// comprovantes que ainda não entraram neles.
  List<Widget> _notices(
    BuildContext context,
    WidgetRef ref,
    DashboardReady state,
  ) {
    const gap = SizedBox(height: CajuiSpacing.lg);
    return [
      if (!state.overview.hasIncome) ...[_missingIncome(context), gap],
      if (state.pendingCaptures > 0) ...[
        _waitingCaptures(ref, state.pendingCaptures),
        gap,
      ],
    ];
  }

  /// A porta para os resumos, já com a frase de hoje à vista (RN-810).
  Widget _summaries(BuildContext context, WidgetRef ref) {
    final today = ref.watch(insightsProvider)?.daily.lines.first;
    return CajuiListRow(
      title: 'Resumos',
      subtitle: today ?? 'Hoje, semana e mês',
      trailing: const CajuiIcon(CajuiIconData.chevronRight),
      semanticLabel: 'Resumos do dia, da semana e do mês, abrir',
      onPressed: () => InsightsPage.open(context),
    );
  }

  Widget _missingIncome(BuildContext context) => CajuiNotice(
    what: 'Falta a renda do mês.',
    meaning:
        'Sem ela não dá para dizer quanto sobra nem quanto dá para gastar. '
        'Os lançamentos continuam valendo.',
    primaryAction: CajuiNoticeAction(
      label: 'Cadastrar a renda',
      onPressed: () => PlanPage.open(context),
    ),
  );

  Widget _waitingCaptures(WidgetRef ref, int pending) => CajuiNotice(
    intent: CajuiNoticeIntent.info,
    what: pending == 1
        ? '1 comprovante esperando conferência.'
        : '$pending comprovantes esperando conferência.',
    meaning: 'Só entram nos números depois que você confirmar.',
    primaryAction: CajuiNoticeAction(
      label: 'Conferir agora',
      onPressed: () =>
          ref.read(homeTabProvider.notifier).select(HomeTab.entries),
    ),
  );
}
