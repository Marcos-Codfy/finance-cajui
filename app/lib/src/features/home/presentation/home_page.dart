import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/budget/application/plan_service.dart';
import 'package:cajui/src/features/budget/presentation/my_bills_page.dart';
import 'package:cajui/src/features/home/application/home_view.dart';
import 'package:cajui/src/features/home/presentation/home_cards.dart';
import 'package:cajui/src/features/home/presentation/home_links.dart';
import 'package:cajui/src/features/home/presentation/home_state.dart';
import 'package:cajui/src/features/home/presentation/web_empty_state.dart';
import 'package:cajui/src/features/ledger/presentation/entries_page.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_page.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:cajui/src/features/settings/presentation/settings_page.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O Início: o mês da planilha de relance e as portas para o resto.
///
/// Responde primeiro quanto dá para gastar nesta semana e se o mês fecha.
/// Um aviso por vez, e só quando há o que fazer.
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
      HomeFirstUse() => const CajuiScreen(
        title: 'Início',
        children: [WebEmptyState()],
      ),
      HomeReady(:final view) => _ready(context, ref, state, view),
    };
  }

  Widget _ready(
    BuildContext context,
    WidgetRef ref,
    HomeReady state,
    HomeView view,
  ) {
    final month = DateLabels.month(view.budget.month).split(' ').first;
    final week = view.week;
    return CajuiScreen(
      title: month[0].toUpperCase() + month.substring(1),
      overline: 'Semana desde ${DateLabels.short(week.from)}',
      trailing: _tools(context, ref, readOnly: state.readOnly),
      footer: state.readOnly
          ? null
          : CajuiButton(
              label: 'Novo lançamento',
              icon: CajuiIconData.plus,
              expand: true,
              onPressed: () => EntryFormPage.open(context),
            ),
      children: [
        ..._notice(context, ref, state),
        ...HomeCards.of(view),
        const SizedBox(height: CajuiSpacing.xl),
        ...HomeLinks.of(context, view),
      ],
    );
  }

  /// A câmera e a galeria no alto — fotografar ou escolher um comprovante é
  /// o caminho mais comum de um lançamento — e os ajustes.
  Widget _tools(BuildContext context, WidgetRef ref, {required bool readOnly}) {
    final capture = ref.watch(captureServiceProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!readOnly && capture.canPhotograph)
          CajuiIconButton(
            icon: CajuiIconData.camera,
            semanticLabel: 'Fotografar comprovante',
            onPressed: () => _open(context, capture.photograph),
          ),
        if (!readOnly && capture.canPickFiles)
          CajuiIconButton(
            icon: CajuiIconData.image,
            semanticLabel: 'Escolher da galeria ou dos arquivos',
            onPressed: () => _open(context, capture.pickFromDevice),
          ),
        CajuiIconButton(
          icon: CajuiIconData.sliders,
          semanticLabel: 'Ajustes',
          onPressed: () => SettingsPage.open(context),
        ),
      ],
    );
  }

  static Future<void> _open(
    BuildContext context,
    Future<bool> Function() open,
  ) async {
    final feedback = CajuiFeedbackScope.of(context);
    if (!await open()) feedback.notice();
  }

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
