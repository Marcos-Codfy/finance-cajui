import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_page.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_view_model.dart';
import 'package:cajui/src/features/receipts/application/capture.dart';
import 'package:cajui/src/features/receipts/application/capture_draft.dart';
import 'package:cajui/src/features/receipts/presentation/capture_header.dart';
import 'package:cajui/src/features/receipts/presentation/capture_view_model.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A tela de conferência de um comprovante (sharing-flow).
///
/// É o mesmo formulário do lançamento à mão, já preenchido com o que a
/// leitura resolveu: mesmos campos, mesmas regras, mesmos erros. A captura
/// não tem um caminho próprio para gravar — e por isso não tem como gravar
/// algo que o lançamento à mão recusaria.
class CaptureConfirmPage extends ConsumerStatefulWidget {
  /// Cria a conferência de [capture], com [waiting] ainda na fila.
  const new({required this.capture, this.waiting = 0, super.key});

  /// A captura a conferir.
  final Capture capture;

  /// Quantos comprovantes esperam depois deste.
  final int waiting;

  @override
  ConsumerState<CaptureConfirmPage> createState() => _CaptureConfirmPageState();
}

class _CaptureConfirmPageState extends ConsumerState<CaptureConfirmPage> {
  /// Descartar apaga o arquivo guardado: pede uma segunda confirmação.
  bool _askingToDiscard = false;

  EntryDraft? _draft;

  CaptureViewModel get _capture => ref.read(captureProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(ledgerProvider).value;
    if (book == null) return const SizedBox.shrink();
    // Montado uma vez só: se o rascunho inicial mudasse a cada reconstrução
    // da tela, o formulário recomeçaria e apagaria o que a pessoa corrigiu.
    final draft = _draft ??= CaptureDraft.of(
      widget.capture,
      book: book,
      today: ref.read(clockProvider).today(),
    );
    return ProviderScope(
      overrides: [initialDraftProvider.overrideWithValue(draft)],
      child: EntryFormPage(
        title: 'Conferir comprovante',
        // Voltar é o caminho seguro: guarda para depois, não perde nada.
        onBack: () => _capture.defer(widget.capture),
        onSaved: (entry) => _capture.confirmed(widget.capture, entry),
        header: (context, edit) =>
            CaptureHeader(capture: widget.capture, book: book, edit: edit),
        extraActions: _askingToDiscard ? [_discardQuestion()] : _actions(),
      ),
    );
  }

  List<Widget> _actions() => [
    CajuiButton(
      label: 'Conferir depois',
      variant: CajuiButtonVariant.secondary,
      expand: true,
      onPressed: () => _capture.defer(widget.capture),
    ),
    CajuiButton(
      label: 'Descartar',
      variant: CajuiButtonVariant.ghost,
      expand: true,
      onPressed: () => setState(() => _askingToDiscard = true),
    ),
  ];

  Widget _discardQuestion() => CajuiNotice(
    what: 'Descartar este comprovante?',
    meaning: 'O arquivo guardado no app é apagado, e nada é lançado.',
    primaryAction: CajuiNoticeAction(
      label: 'Descartar',
      onPressed: () => _capture.discard(widget.capture),
    ),
    secondaryAction: CajuiNoticeAction(
      label: 'Manter',
      onPressed: () => setState(() => _askingToDiscard = false),
    ),
  );
}
