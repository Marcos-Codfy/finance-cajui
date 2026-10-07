import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_notice.dart';
import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_page.dart';
import 'package:cajui/src/features/receipts/application/capture_route.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:cajui/src/features/receipts/presentation/capture_confirm_page.dart';
import 'package:cajui/src/features/receipts/presentation/capture_state.dart';
import 'package:cajui/src/features/receipts/presentation/capture_view_model.dart';
import 'package:cajui/src/features/receipts/presentation/income_capture_page.dart';
import 'package:cajui/src/features/receipts/presentation/not_an_expense_page.dart';
import 'package:cajui/src/features/receipts/presentation/statement_review_page.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A tela que aparece quando chega um comprovante: lendo, conferindo ou
/// explicando por que não deu.
class CapturePage extends ConsumerWidget {
  /// Cria a tela de captura.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(captureProvider);
    return switch (state) {
      CaptureIdle() => const SizedBox.shrink(),
      CaptureReading() => _reading(context, state),
      CaptureReady() => _ready(state),
      CaptureFailed(:final error) => _failed(context, ref, error),
    };
  }

  /// A tela que sabe tratar o que o documento é. A chave faz cada tela
  /// renascer a cada comprovante da fila.
  static Widget _ready(CaptureReady state) {
    final capture = state.capture;
    final key = ValueKey((capture.source.id, state.asExpense));
    final route = state.asExpense
        ? CaptureRoute.expense
        : CaptureRoute.of(capture.proposal);
    return switch (route) {
      CaptureRoute.statement => StatementReviewPage(key: key, capture: capture),
      CaptureRoute.income => IncomeCapturePage(key: key, capture: capture),
      CaptureRoute.notAnExpense => NotAnExpensePage(key: key, capture: capture),
      CaptureRoute.expense => CaptureConfirmPage(
        key: key,
        capture: capture,
        waiting: state.waiting,
      ),
    };
  }

  Widget _reading(BuildContext context, CaptureReading state) {
    final (page, of) = (state.page, state.of);
    final colors = CajuiTheme.of(context).colors;
    return CajuiScreen(
      title: 'Lendo o comprovante',
      overline: _waitingLabel(state.waiting),
      children: [
        const Text('Lendo o comprovante.'),
        const SizedBox(height: CajuiSpacing.xl),
        Align(
          alignment: Alignment.centerLeft,
          child: CajuiLoadingDots(
            color: colors.action.primary,
            semanticLabel: 'Lendo o comprovante',
          ),
        ),
        if (page != null && of != null && of > 1) ...[
          const SizedBox(height: CajuiSpacing.md),
          Text('página $page de $of'),
        ],
      ],
    );
  }

  /// "e mais 2 na fila", quando a pessoa compartilhou vários de uma vez.
  static String? _waitingLabel(int waiting) => switch (waiting) {
    0 => null,
    1 => 'e mais 1 na fila',
    _ => 'e mais $waiting na fila',
  };

  Widget _failed(BuildContext context, WidgetRef ref, PresentedError error) {
    return CajuiScreen(
      title: 'Comprovante',
      onBack: ref.read(captureProvider.notifier).dismiss,
      children: [
        ErrorNotice(
          error: error,
          onAction: (index) => _resolve(context, ref, error, index),
        ),
      ],
    );
  }

  /// A saída escolhida no aviso. Cada código do catálogo tem as suas; o que
  /// acontece fora do app — abrir o armazenamento, por exemplo — só dispensa
  /// o aviso.
  Future<void> _resolve(
    BuildContext context,
    WidgetRef ref,
    PresentedError error,
    int index,
  ) async {
    final capture = ref.read(captureProvider.notifier);
    final label = error.text.actions[index];
    if (error.code == ErrorCode.capt07 && index == 0) {
      await capture.retry();
      return;
    }
    await capture.dismiss();
    // "Tirar outra foto" abre a câmera de novo (ADR-017): foto escura ou
    // torta é o caso comum de cupom, e refazer é um toque.
    if (label.startsWith('Tirar outra')) {
      await ref.read(captureServiceProvider).photograph();
      return;
    }
    // "Digitar os dados" e "Digitar o valor" levam ao lançamento à mão.
    if (label.startsWith('Digitar') && context.mounted) {
      await EntryFormPage.open(context);
    }
  }
}
