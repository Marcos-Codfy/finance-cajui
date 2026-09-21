import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_notice.dart';
import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_page.dart';
import 'package:cajui/src/features/receipts/presentation/capture_confirm_page.dart';
import 'package:cajui/src/features/receipts/presentation/capture_state.dart';
import 'package:cajui/src/features/receipts/presentation/capture_view_model.dart';
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
      CaptureReady(:final capture) => CaptureConfirmPage(
        // A chave faz o formulário renascer a cada comprovante da fila.
        key: ValueKey(capture.source.id),
        capture: capture,
        waiting: state.waiting,
      ),
      CaptureFailed(:final error) => _failed(context, ref, error),
    };
  }

  Widget _reading(BuildContext context, CaptureReading state) {
    final (page, of) = (state.page, state.of);
    final colors = CajuiTheme.of(context).colors;
    return CajuiScreen(
      title: 'Lendo o comprovante',
      overline: _waitingLabel(state.waiting),
      children: [
        const Text('Lendo o comprovante no seu aparelho.'),
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
    final capture = ref.read(captureProvider.notifier);
    return CajuiScreen(
      title: 'Comprovante',
      onBack: capture.dismiss,
      children: [
        ErrorNotice(
          error: error,
          onAction: (index) async {
            final label = error.text.actions[index];
            if (error.code == ErrorCode.capt07 && index == 0) {
              await capture.retry();
              return;
            }
            await capture.dismiss();
            // "Digitar os dados" e "Digitar o valor" levam ao lançamento à
            // mão; as outras saídas acontecem fora do app.
            if (label.startsWith('Digitar') && context.mounted) {
              await EntryFormPage.open(context);
            }
          },
        ),
      ],
    );
  }
}
