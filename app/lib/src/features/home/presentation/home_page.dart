import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/budget/application/plan_service.dart';
import 'package:cajui/src/features/budget/presentation/my_bills_page.dart';
import 'package:cajui/src/features/export/application/export_month.dart';
import 'package:cajui/src/features/home/application/home_view.dart';
import 'package:cajui/src/features/home/presentation/home_cards.dart';
import 'package:cajui/src/features/home/presentation/home_links.dart';
import 'package:cajui/src/features/home/presentation/home_state.dart';
import 'package:cajui/src/features/home/presentation/month_celebration.dart';
import 'package:cajui/src/features/home/presentation/web_empty_state.dart';
import 'package:cajui/src/features/home_widget/presentation/widget_arrival.dart';
import 'package:cajui/src/features/ledger/application/sync_now.dart';
import 'package:cajui/src/features/ledger/presentation/entries_page.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_page.dart';
import 'package:cajui/src/features/receipts/presentation/capture_tools.dart';
import 'package:cajui/src/features/settings/presentation/settings_page.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O Início: o mês da planilha de relance e as portas para o resto.
///
/// Responde primeiro se o mês fecha — a sobra, ou quanto falta. Um aviso
/// por vez, e só quando há o que fazer.
class HomePage extends ConsumerWidget {
  /// Cria o Início.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeStateProvider);
    return switch (state) {
      HomeLoading() => const CajuiScreen(
        title: 'Início',
        children: [
          CajuiSkeleton(height: 148),
          SizedBox(height: CajuiSpacing.lg),
          CajuiSkeleton(height: 112),
        ],
      ),
      // Os ajustes também aqui: é por eles que a consulta sai (ADR-027), e
      // a web de quem começou do zero passa a primeira visita nesta tela.
      HomeFirstUse() => CajuiScreen(
        title: 'Início',
        trailing: _tools(context, readOnly: true),
        children: const [WebEmptyState()],
      ),
      // Do topo, puxar para baixo força a sincronização (16/10/2026).
      HomeReady(:final view) => CajuiPullToRefresh(
        onRefresh: () => ref.read(syncNowProvider)(),
        child: _ready(context, ref, state, view),
      ),
    };
  }

  /// Os números do mês. Tocar no número do widget os traz atravessando o
  /// vidro.
  Widget _cards(WidgetRef ref, HomeView view, {required bool visible}) =>
      CajuiGlassArrival(
        arrival: ref.watch(widgetArrivalProvider),
        child: HomeCards.of(view, party: _party(ref, view, visible: visible)),
      );

  Widget _ready(
    BuildContext context,
    WidgetRef ref,
    HomeReady state,
    HomeView view,
  ) {
    final month = DateLabels.month(view.budget.month).split(' ').first;
    // O Início fica montado por baixo da conversa e das telas abertas por
    // cima: só à vista ele faz festa.
    final visible = TickerMode.valuesOf(context).enabled;
    // A rolagem em profundidade e o travelling de câmera na entrada (pedido
    // do dono: "3d scrolling com animações cinematográficas"). A chave é o
    // mês: a entrada roda de novo quando ele vira, e não a cada lançamento.
    return CajuiScreen(
      title: month[0].toUpperCase() + month.substring(1),
      trailing: _tools(context, readOnly: state.readOnly),
      footer: state.readOnly ? null : _newEntry(context),
      depth: true,
      cinematic: true,
      replayKey: view.budget.month,
      children: [
        ..._notice(context, ref, state),
        _cards(ref, view, visible: visible),
        const SizedBox(height: CajuiSpacing.xl),
        ..._links(context, ref, view),
      ],
    );
  }

  /// As portas do Início, com a planilha do mês que o Início abre.
  static List<Widget> _links(
    BuildContext context,
    WidgetRef ref,
    HomeView view,
  ) => HomeLinks.of(
    context,
    view,
    export: () => ref.read(exportMonthProvider).call(view.budget.month),
  );

  static Widget _newEntry(BuildContext context) => CajuiButton(
    label: 'Novo lançamento',
    icon: CajuiIconData.plus,
    expand: true,
    onPressed: () => EntryFormPage.open(context),
  );

  /// Se o mês no verde está em festa; a primeira vez é anotada, para não
  /// repetir na próxima abertura (escolha 5 do dono).
  static bool _party(WidgetRef ref, HomeView view, {required bool visible}) {
    final month = view.budget.month;
    final celebration = ref.watch(monthCelebrationProvider);
    final party =
        view.budget.closes && celebration.party(month, visible: visible);
    if (party) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => celebration.mark(month),
      );
    }
    return party;
  }

  /// A câmera e a galeria no alto — fotografar ou escolher um comprovante é
  /// o caminho mais comum de um lançamento — e os ajustes.
  Widget _tools(BuildContext context, {required bool readOnly}) => CaptureTools(
    readOnly: readOnly,
    extra: [
      CajuiIconButton(
        icon: CajuiIconData.sliders,
        semanticLabel: 'Ajustes',
        onPressed: () => SettingsPage.open(context),
      ),
    ],
  );

  /// O aviso que vem antes dos números — um só: comprovante esperando, ou a
  /// sugestão de contas depois de um mês sem plano (RN-1050).
  List<Widget> _notice(BuildContext context, WidgetRef ref, HomeReady state) {
    final suggestion = state.view.suggestion;
    final notice = switch (state) {
      HomeReady(pendingCaptures: > 0) => _waiting(context, state),
      HomeReady(readOnly: false) when suggestion != null => _suggest(
        context,
        ref,
        suggestion,
      ),
      _ => null,
    };
    if (notice == null) return const [];
    return [notice, const SizedBox(height: CajuiSpacing.lg)];
  }

  Widget _waiting(BuildContext context, HomeReady state) {
    final pending = state.pendingCaptures;
    return CajuiNotice(
      intent: CajuiNoticeIntent.info,
      what: pending == 1
          ? '1 comprovante esperando conferência.'
          : '$pending comprovantes esperando conferência.',
      meaning: 'Só entra nos números depois que você confirmar.',
      primaryAction: state.readOnly
          ? null
          : CajuiNoticeAction(
              label: 'Conferir agora',
              onPressed: () => EntriesPage.open(context),
            ),
    );
  }

  Widget _suggest(
    BuildContext context,
    WidgetRef ref,
    PlanSuggestion suggestion,
  ) {
    final first = suggestion.lines.first;
    final amount = BrlFormatter.format(first.amount.cents);
    return CajuiNotice(
      intent: CajuiNoticeIntent.info,
      what: 'Você gasta uns $amount por mês em ${first.name}.',
      meaning:
          'Dá para usar o que você já gastou como suas contas do mês: '
          '${suggestion.lines.length} linhas, e você ajusta depois.',
      primaryAction: CajuiNoticeAction(
        label: 'Usar como minhas contas',
        onPressed: () => _accept(ref, suggestion),
      ),
      secondaryAction: CajuiNoticeAction(
        label: 'Ver minhas contas',
        onPressed: () => MyBillsPage.open(context),
      ),
    );
  }

  static Future<void> _accept(WidgetRef ref, PlanSuggestion suggestion) {
    final plan = ref.read(financesProvider)?.plan ?? BudgetPlan.empty;
    return ref
        .read(planServiceProvider)
        .define(plan.copyWith(lines: suggestion.lines));
  }
}
