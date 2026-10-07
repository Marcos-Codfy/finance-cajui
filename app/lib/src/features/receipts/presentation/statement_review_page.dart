import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/receipts/application/capture.dart';
import 'package:cajui/src/features/receipts/application/statement_import.dart';
import 'package:cajui/src/features/receipts/presentation/capture_view_model.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Um extrato lido: as movimentações em lista, para marcar o que lançar
/// (RN-707).
///
/// Já vêm marcadas as despesas que ainda não estão no Cajui. Entrada fica
/// desmarcada — marcar a faz virar recebimento —, e pagamento de fatura e
/// transferência entre contas suas aparecem só para mostrar que foram
/// lidos: nunca viram despesa (RN-756, RN-759).
class StatementReviewPage extends ConsumerStatefulWidget {
  /// Cria a tela do extrato de [capture].
  const new({required this.capture, super.key});

  /// O extrato lido.
  final Capture capture;

  @override
  ConsumerState<StatementReviewPage> createState() =>
      _StatementReviewPageState();
}

class _StatementReviewPageState extends ConsumerState<StatementReviewPage> {
  Set<int>? _selected;
  Set<int> _known = const {};
  bool _saving = false;

  List<StatementLine> get _lines => widget.capture.proposal.lines;

  CaptureViewModel get _capture => ref.read(captureProvider.notifier);

  void _toggle(int index) => setState(() {
    final selected = _selected!;
    selected.contains(index) ? selected.remove(index) : selected.add(index);
  });

  Future<void> _record() async {
    setState(() => _saving = true);
    final feedback = CajuiFeedbackScope.of(context);
    await ref.read(statementImportProvider).record(widget.capture, {
      ...?_selected,
    });
    feedback.saved();
    await _capture.closed(widget.capture);
  }

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(ledgerProvider).value;
    if (book == null) return const SizedBox.shrink();
    // Marcadas uma vez só: a pessoa mexe, e a lista não volta atrás.
    if (_selected == null) {
      _known = StatementImport.alreadyThere(_lines, book);
      _selected = StatementImport.preselected(_lines, book);
    }
    final today = ref.read(clockProvider).today();
    return CajuiScreen(
      title: 'Extrato',
      overline: '${_lines.length} movimentações',
      onBack: () => _capture.defer(widget.capture),
      footer: _footer(),
      children: [
        _explanation(context),
        const SizedBox(height: CajuiSpacing.lg),
        for (final (index, line) in _lines.indexed)
          _row(book, index, line, today),
      ],
    );
  }

  Widget _explanation(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Text(
      'Marquei as despesas que ainda não estão no Cajui. Toque numa linha '
      'para marcar ou desmarcar.',
      style: theme.typography.body.copyWith(color: theme.colors.text.muted),
    );
  }

  Widget _row(LedgerBook book, int index, StatementLine line, LocalDate today) {
    final selectable = StatementImport.isSelectable(line);
    final on = _selected!.contains(index);
    final what = _what(book, line);
    final day = DateLabels.day(line.occurredOn, today: today);
    final note = _known.contains(index) ? ' · parece já lançado' : '';
    return CajuiListRow(
      title: line.description,
      subtitle: '$what · $day$note',
      semanticLabel:
          '${line.description}, ${BrlFormatter.format(line.amount.cents)}, '
          '$what, $day$note${selectable ? (on ? ', marcada' : ', desmarcada') : ''}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CajuiAmountText(line.amount.cents),
          if (selectable) ...[
            const SizedBox(width: CajuiSpacing.sm),
            CajuiSwitch(
              value: on,
              semanticLabel: 'Lançar ${line.description}',
              onChanged: (_) => _toggle(index),
            ),
          ],
        ],
      ),
      onPressed: selectable ? () => _toggle(index) : null,
    );
  }

  /// O que a linha é, em palavras: a categoria da despesa, ou por que ela
  /// não vira despesa.
  static String _what(LedgerBook book, StatementLine line) =>
      switch (line.kind) {
        StatementLineKind.expense =>
          book.categories
                  .where((category) => category.id == line.categoryId)
                  .firstOrNull
                  ?.name ??
              'Despesa',
        StatementLineKind.income => 'Entrada',
        StatementLineKind.cardPayment => 'Pagamento de fatura, não é despesa',
        StatementLineKind.ownTransfer => 'Entre contas suas, não é despesa',
      };

  Widget _footer() {
    final count = _selected?.length ?? 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CajuiButton(
          label: count == 0
              ? 'Marque o que lançar'
              : count == 1
              ? 'Lançar 1 movimentação'
              : 'Lançar $count movimentações',
          expand: true,
          loading: _saving,
          onPressed: count == 0 || _saving ? null : _record,
        ),
        const SizedBox(height: CajuiSpacing.sm),
        CajuiButton(
          label: 'Descartar',
          variant: CajuiButtonVariant.ghost,
          expand: true,
          onPressed: () => _capture.discard(widget.capture),
        ),
      ],
    );
  }
}
