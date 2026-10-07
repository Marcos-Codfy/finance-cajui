import 'package:cajui/src/app/home_tab.dart';
import 'package:cajui/src/app/home_tab_controller.dart';
import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/budget/application/month_overview.dart';
import 'package:cajui/src/features/budget/presentation/adjustments_page.dart';
import 'package:cajui/src/features/budget/presentation/plan_page.dart';
import 'package:cajui/src/features/dashboard/presentation/dashboard_blocks.dart';
import 'package:cajui/src/features/dashboard/presentation/dashboard_state.dart';
import 'package:cajui/src/features/dashboard/presentation/web_empty_state.dart';
import 'package:cajui/src/features/insights/application/insights.dart';
import 'package:cajui/src/features/insights/presentation/insights_page.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_page.dart';
import 'package:cajui/src/features/ledger/presentation/voucher_balance_page.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O painel: a primeira tela. Responde uma pergunta antes de qualquer outra —
/// quanto dá para gastar nesta semana — e põe a câmera a um toque.
///
/// Um aviso por vez, e só quando há o que fazer: o painel de uma pessoa não
/// é um quadro de pendências.
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
      DashboardFirstUse() => const CajuiScreen(
        title: 'Painel',
        children: [WebEmptyState()],
      ),
      DashboardReady(:final overview) => _ready(context, ref, state, overview),
    };
  }

  Widget _ready(
    BuildContext context,
    WidgetRef ref,
    DashboardReady state,
    MonthOverview overview,
  ) {
    final week = overview.week.week;
    final month = DateLabels.month(overview.plan.month).split(' ').first;
    // A consulta mostra o mês e não lança, não edita o plano nem acerta o
    // vale: gravar ali estoura por construção (T-12), e a porta nem aparece.
    final consulta = !ref.read(ledgerUplinkProvider).isPaired;
    return CajuiScreen(
      title: month[0].toUpperCase() + month.substring(1),
      overline: 'Semana de ${week.start.day} a ${week.end.day}',
      trailing: consulta ? null : _tools(context, ref),
      footer: consulta ? null : _newEntryButton(context),
      children: [
        ..._notice(context, ref, state, consulta: consulta),
        ...DashboardBlocks.of(overview),
        _summaries(context, ref),
      ],
    );
  }

  /// A câmera, a galeria e o plano, no alto: fotografar ou escolher um
  /// comprovante é o caminho mais comum de um lançamento, e começa na
  /// primeira tela.
  Widget _tools(BuildContext context, WidgetRef ref) {
    final capture = ref.watch(captureServiceProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (capture.canPhotograph)
          CajuiIconButton(
            icon: CajuiIconData.camera,
            semanticLabel: 'Fotografar comprovante',
            onPressed: () => _photograph(context, capture.photograph),
          ),
        if (capture.canPickFiles)
          CajuiIconButton(
            icon: CajuiIconData.image,
            semanticLabel: 'Escolher da galeria ou dos arquivos',
            onPressed: () => _photograph(context, capture.pickFromDevice),
          ),
        CajuiIconButton(
          icon: CajuiIconData.sliders,
          semanticLabel: 'Plano do mês',
          onPressed: () => PlanPage.open(context),
        ),
      ],
    );
  }

  static Future<void> _photograph(
    BuildContext context,
    Future<bool> Function() open,
  ) async {
    final feedback = CajuiFeedbackScope.of(context);
    if (!await open()) feedback.notice();
  }

  Widget _newEntryButton(BuildContext context) => CajuiButton(
    label: 'Novo lançamento',
    icon: CajuiIconData.plus,
    expand: true,
    onPressed: () => EntryFormPage.open(context),
  );

  /// O aviso que precisa ser dito antes dos números — **um só**, o mais
  /// urgente: vale lançado além do saldo, mês que não fecha, comprovante à
  /// espera. Renda que falta não é aviso: o cartão da sobra já diz.
  List<Widget> _notice(
    BuildContext context,
    WidgetRef ref,
    DashboardReady state, {
    required bool consulta,
  }) {
    final overview = state.overview;
    final overdrawn = overview.voucher.overdrawn;
    final Widget? notice;
    if (overdrawn.isPositive) {
      notice = _voucherOverdrawn(context, overdrawn, consulta: consulta);
    } else if (overview.indicators.requiredAdjustment.isPositive) {
      notice = _howToClose(context, overview, consulta: consulta);
    } else if (state.pendingCaptures > 0) {
      notice = _waitingCaptures(ref, state.pendingCaptures);
    } else {
      notice = null;
    }
    if (notice == null) return const [];
    return [notice, const SizedBox(height: CajuiSpacing.lg)];
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

  /// O mês não fecha: o painel deixa de só informar e passa a oferecer o
  /// caminho que o domínio já sabia calcular (RN-662).
  Widget _howToClose(
    BuildContext context,
    MonthOverview overview, {
    required bool consulta,
  }) {
    final indicators = overview.indicators;
    final falta = MoneyFormat.brl(indicators.requiredAdjustment);
    return CajuiNotice(
      intent: CajuiNoticeIntent.info,
      what: indicators.closesByAdjustingVariables
          ? 'Dá para cobrir sem mexer nos fixos.'
          : 'Faltam $falta para o mês fechar.',
      meaning: indicators.closesByAdjustingVariables
          ? 'Faltam $falta, e há folga nos variáveis para remanejar.'
          : 'Os variáveis cobrem parte; o resto depende da renda, de um '
                'fixo ou de uma dívida.',
      // Os ajustes se aplicam ao plano, e a consulta não grava.
      primaryAction: consulta
          ? null
          : CajuiNoticeAction(
              label: 'Ver os ajustes',
              onPressed: () => AdjustmentsPage.open(context),
            ),
    );
  }

  /// Há mais gasto lançado no vale do que saldo (RN-124): o saldo mostrado
  /// é zero, e o aviso diz o porquê e por onde se acerta.
  Widget _voucherOverdrawn(
    BuildContext context,
    Money overdrawn, {
    required bool consulta,
  }) => CajuiNotice(
    intent: CajuiNoticeIntent.info,
    what: 'O vale tem ${MoneyFormat.brl(overdrawn)} lançados além do saldo.',
    meaning:
        'Acontece quando dois celulares usam o mesmo saldo sem '
        'internet, ou quando falta lançar um crédito. Confira o saldo '
        'no aplicativo da operadora.',
    primaryAction: consulta
        ? null
        : CajuiNoticeAction(
            label: 'Acertar o saldo',
            onPressed: () => VoucherBalancePage.open(context),
          ),
  );

  Widget _waitingCaptures(WidgetRef ref, int pending) => CajuiNotice(
    intent: CajuiNoticeIntent.info,
    what: pending == 1
        ? '1 comprovante esperando conferência.'
        : '$pending comprovantes esperando conferência.',
    meaning: 'Só entra nos números depois que você confirmar.',
    primaryAction: CajuiNoticeAction(
      label: 'Conferir agora',
      onPressed: () =>
          ref.read(homeTabProvider.notifier).select(HomeTab.entries),
    ),
  );
}
