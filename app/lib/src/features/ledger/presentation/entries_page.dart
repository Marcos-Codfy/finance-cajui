import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_notice.dart';
import 'package:cajui/src/core/errors/error_texts.g.dart';
import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/presentation/entries_state.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_page.dart';
import 'package:cajui/src/features/ledger/presentation/entry_row.dart';
import 'package:cajui/src/features/ledger/presentation/month_spending_card.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:cajui/src/features/receipts/presentation/pending_captures_card.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Os lançamentos do mês, e as portas para acrescentar um: fotografar o
/// comprovante, receber um compartilhado ou lançar à mão.
class EntriesPage extends ConsumerWidget {
  /// Cria a tela de lançamentos.
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(entriesStateProvider);
    return CajuiScreen(
      title: 'Lançamentos',
      overline: state is EntriesReady ? DateLabels.month(state.month) : null,
      footer: _footer(context, ref, state),
      children: switch (state) {
        EntriesLoading() => _loading,
        EntriesFailed() => [_failure(ref)],
        EntriesReady() => _ready(state),
      },
    );
  }

  /// As duas portas de entrada de uma despesa: fotografar o comprovante de
  /// papel e lançar à mão. Fotografar vem primeiro porque é o caminho do
  /// cupom de mercado, que não dá para compartilhar (ADR-017).
  Widget _footer(BuildContext context, WidgetRef ref, EntriesState state) {
    final ready = state is EntriesReady;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ref.watch(captureServiceProvider).canPhotograph) ...[
          CajuiButton(
            label: 'Fotografar comprovante',
            variant: CajuiButtonVariant.secondary,
            icon: CajuiIconData.camera,
            expand: true,
            onPressed: ready ? () => _photograph(context, ref) : null,
          ),
          const SizedBox(height: CajuiSpacing.sm),
        ],
        CajuiButton(
          label: 'Lançar',
          icon: CajuiIconData.plus,
          expand: true,
          onPressed: ready ? () => EntryFormPage.open(context) : null,
        ),
      ],
    );
  }

  /// A foto não volta por aqui: ela entra na fila da captura, e a conferência
  /// abre por cima do app, igual à do compartilhamento.
  static Future<void> _photograph(BuildContext context, WidgetRef ref) async {
    final feedback = CajuiFeedbackScope.of(context);
    final opened = await ref.read(captureServiceProvider).photograph();
    if (!opened) feedback.notice();
  }

  /// Carregando tem a forma do que vem: três linhas de lançamento.
  static const _loading = <Widget>[
    CajuiSkeleton(height: 96),
    SizedBox(height: CajuiSpacing.xl),
    CajuiSkeleton(height: 56),
    SizedBox(height: CajuiSpacing.sm),
    CajuiSkeleton(height: 56),
    SizedBox(height: CajuiSpacing.sm),
    CajuiSkeleton(height: 56),
  ];

  Widget _failure(WidgetRef ref) {
    return ErrorNotice(
      error: (
        code: ErrorCode.app01,
        text: ErrorTexts.of(ErrorCode.app01).fill(const {'fila': ''}),
      ),
      // "Reabrir" aqui é abrir o livro de novo; copiar o código chega com a
      // tela de diagnóstico.
      onAction: (_) => ref.invalidate(ledgerProvider),
    );
  }

  List<Widget> _ready(EntriesReady state) {
    return [
      const PendingCapturesCard(),
      MonthSpendingCard(spent: state.spent, voucher: state.book.voucher),
      const SizedBox(height: CajuiSpacing.xl),
      if (state.entries.isEmpty)
        const CajuiEmptyState(
          title: 'Nada lançado ainda',
          message:
              'Fotografe o comprovante do mercado, compartilhe um Pix de '
              'qualquer app, ou lance o primeiro à mão.',
        ),
      for (final (index, entry) in state.entries.indexed)
        CajuiEntrance(
          index: index,
          child: EntryRow(entry: entry, book: state.book, today: state.today),
        ),
    ];
  }
}
