import 'dart:async';

import 'package:cajui/src/app/home_tab.dart';
import 'package:cajui/src/app/home_tab_controller.dart';
import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/auth/application/device_enrollment.dart';
import 'package:cajui/src/features/auth/presentation/enroll_page.dart';
import 'package:cajui/src/features/budget/application/month_overview.dart';
import 'package:cajui/src/features/budget/presentation/adjustments_page.dart';
import 'package:cajui/src/features/budget/presentation/plan_page.dart';
import 'package:cajui/src/features/dashboard/presentation/dashboard_blocks.dart';
import 'package:cajui/src/features/dashboard/presentation/dashboard_state.dart';
import 'package:cajui/src/features/insights/application/insights.dart';
import 'package:cajui/src/features/insights/presentation/insights_page.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:cajui/src/features/ledger/application/sync_providers.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_page.dart';
import 'package:cajui/src/features/ledger/presentation/sync_page.dart';
import 'package:cajui/src/features/ledger/presentation/voucher_balance_page.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
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
      DashboardFirstUse() => _firstUse(context, ref),
      DashboardReady(:final overview) => _ready(context, ref, state, overview),
    };
  }

  /// A primeira vez — ou, na web, a consulta que ainda não entrou.
  ///
  /// A web **não pode oferecer "Começar"**: ela não tem onde guardar, e o
  /// plano montado ali se perderia ao fechar a aba. O que ela oferece é a
  /// entrada com o código do celular; "recarregue a página", que era o
  /// conselho de antes, perdia a sessão — e a página nunca saía daqui.
  Widget _firstUse(BuildContext context, WidgetRef ref) {
    final consulta = !ref.read(ledgerUplinkProvider).isPaired;
    return CajuiScreen(
      title: 'Painel',
      children: [
        CajuiEmptyState(
          illustration: const CajuiHeroFruit(),
          title: consulta
              ? 'Nada deste mês por aqui ainda'
              : 'Seu mês começa aqui',
          message: consulta
              ? 'Esta é a consulta: o plano e os lançamentos ficam no '
                    'celular e chegam aqui pelo servidor. Entre com o código '
                    'que o celular mostra em Ajustes, Aparelhos com acesso, '
                    'Abrir no computador.'
              : 'Com a renda e as contas fixas, o Cajui já diz quanto dá '
                    'para gastar por semana. Leva uns cinco minutos.',
          action: CajuiNoticeAction(
            label: consulta ? 'Entrar com o código' : 'Começar',
            onPressed: () =>
                consulta ? EnrollPage.open(context) : PlanPage.open(context),
          ),
        ),
      ],
    );
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
      trailing: consulta ? null : _planButton(context),
      footer: consulta ? null : _newEntryButton(context),
      children: [
        ..._notices(context, ref, state, consulta: consulta),
        ...DashboardBlocks.of(overview),
        _summaries(context, ref),
      ],
    );
  }

  Widget _planButton(BuildContext context) => CajuiIconButton(
    icon: CajuiIconData.sliders,
    semanticLabel: 'Plano do mês',
    onPressed: () => PlanPage.open(context),
  );

  Widget _newEntryButton(BuildContext context) => CajuiButton(
    label: 'Novo lançamento',
    icon: CajuiIconData.plus,
    expand: true,
    onPressed: () => EntryFormPage.open(context),
  );

  /// O que precisa ser dito antes dos números: renda que falta e
  /// comprovantes que ainda não entraram neles.
  List<Widget> _notices(
    BuildContext context,
    WidgetRef ref,
    DashboardReady state, {
    required bool consulta,
  }) {
    const gap = SizedBox(height: CajuiSpacing.lg);
    final stopped = ref.watch(quietSendProvider).value == false;
    final overview = state.overview;
    final overdrawn = overview.voucher.overdrawn;
    return [
      if (!consulta && stopped) ...[_sendNotice(context, ref), gap],
      if (!overview.hasIncome) ...[
        _missingIncome(context, consulta: consulta),
        gap,
      ],
      if (state.pendingCaptures > 0) ...[
        _waitingCaptures(ref, state.pendingCaptures),
        gap,
      ],
      if (overdrawn.isPositive) ...[
        _voucherOverdrawn(context, overdrawn, consulta: consulta),
        gap,
      ],
      if (overview.indicators.requiredAdjustment.isPositive) ...[
        _howToClose(context, overview, consulta: consulta),
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

  /// Nada sobe sozinho agora — e o motivo decide o que se oferece. Aparelho
  /// que o servidor não conhece precisa do cadastro, e não de um envio: o
  /// primeiro uso no celular mostrou o painel pedindo a digital a quem
  /// faltava era o código.
  Widget _sendNotice(BuildContext context, WidgetRef ref) =>
      ref.watch(deviceEnrollmentProvider).isRefused
      ? _notEnrolled(context, ref)
      : _sendStopped(context);

  Widget _notEnrolled(BuildContext context, WidgetRef ref) => CajuiNotice(
    intent: CajuiNoticeIntent.info,
    what: 'Este celular ainda não está cadastrado no servidor.',
    meaning:
        'O que você lançar fica guardado aqui. Para o outro celular, a web '
        'e o assistente verem, cadastre este aparelho com o código que o '
        'servidor gera.',
    primaryAction: CajuiNoticeAction(
      label: 'Cadastrar este aparelho',
      onPressed: () => unawaited(_enroll(context, ref)),
    ),
  );

  /// Cadastrou, já segue para o envio: é ele que leva o que está aqui e
  /// traz o que o outro celular fez.
  Future<void> _enroll(BuildContext context, WidgetRef ref) async {
    final enrolled = await EnrollPage.open(context);
    if (!(enrolled ?? false) || !context.mounted) return;
    ref.invalidate(quietSendProvider);
    await SyncPage.open(context);
  }

  /// O envio automático está parado (BL-061): falta a digital do dia, ou
  /// não há rede. Até o próximo envio, o que for lançado não chega ao
  /// outro celular, à web nem ao assistente — e a tela passa a dizer isso.
  Widget _sendStopped(BuildContext context) => CajuiNotice(
    intent: CajuiNoticeIntent.info,
    what: 'O envio automático está parado.',
    meaning:
        'O que você lançar fica guardado neste celular. Para o outro '
        'celular, a web e o assistente verem, faça um envio: ele pede a '
        'digital uma vez por dia.',
    primaryAction: CajuiNoticeAction(
      label: 'Enviar agora',
      onPressed: () => SyncPage.open(context),
    ),
  );

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

  Widget _missingIncome(BuildContext context, {required bool consulta}) =>
      CajuiNotice(
        what: 'Falta a renda do mês.',
        meaning:
            'Sem ela não dá para dizer quanto sobra nem quanto dá para '
            'gastar. Os lançamentos continuam valendo.',
        primaryAction: consulta
            ? null
            : CajuiNoticeAction(
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
