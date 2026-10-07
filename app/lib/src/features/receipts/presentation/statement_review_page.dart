import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/receipts/application/capture.dart';
import 'package:cajui/src/features/receipts/application/statement_import.dart';
import 'package:cajui/src/features/receipts/presentation/capture_view_model.dart';
import 'package:cajui/src/features/receipts/presentation/statement_line_labels.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Um extrato lido: as movimentações em lista, para marcar o que lançar
/// (RN-707).
///
/// Já vêm marcadas as despesas certas que ainda não estão no Cajui. Entrada
/// fica desmarcada — marcar a faz virar recebimento —, e pagamento de fatura
/// e transferência entre contas suas aparecem para mostrar que foram lidos
/// (RN-756, RN-759); em dúvida, dá para marcar, e aí viram despesa.
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
  final Set<int> _done = {};
  String? _refusal;
  bool _saving = false;

  List<StatementLine> get _lines => widget.capture.proposal.lines;

  void _toggle(int index) => setState(() {
    final selected = _selected!;
    selected.contains(index) ? selected.remove(index) : selected.add(index);
  });

  Future<void> _record() async {
    // Lidos antes de esperar: a tela pode sair enquanto grava.
    final capture = ref.read(captureProvider.notifier);
    final import = ref.read(statementImportProvider);
    final feedback = CajuiFeedbackScope.of(context);
    setState(() => _saving = true);
    try {
      final outcome = await import.record(widget.capture, {...?_selected});
      if (outcome.refused.isEmpty) {
        feedback.saved();
        await capture.closed(widget.capture);
        return;
      }
      if (mounted) setState(() => _keepRefused(outcome));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// O que entrou sai da lista de marcadas; o que o domínio recusou fica, com
  /// o motivo do catálogo — nada some em silêncio.
  void _keepRefused(StatementOutcome outcome) {
    _done.addAll(outcome.recorded);
    _selected!.removeAll(outcome.recorded);
    final MapEntry(key: index, value: failure) = outcome.refused.entries.first;
    final count = outcome.recorded.length;
    _refusal =
        '${count == 0 ? 'Nada entrou' : 'Lancei $count'}. '
        '"${_lines[index].description}" não entrou: '
        '${FailurePresenter.present(failure).text.message}';
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
      onBack: _saving ? null : () => _vm.defer(widget.capture),
      footer: _footer(),
      children: [
        _explanation(context),
        const SizedBox(height: CajuiSpacing.lg),
        for (final (index, line) in _lines.indexed)
          _row(book, index, line, today),
      ],
    );
  }

  CaptureViewModel get _vm => ref.read(captureProvider.notifier);

  Widget _explanation(BuildContext context) {
    final refusal = _refusal;
    if (refusal != null) {
      return CajuiNotice(what: refusal, intent: CajuiNoticeIntent.info);
    }
    final theme = CajuiTheme.of(context);
    return Text(
      'Marquei as despesas que ainda não estão no Cajui. Toque numa linha '
      'para marcar ou desmarcar.',
      style: theme.typography.body.copyWith(color: theme.colors.text.muted),
    );
  }

  Widget _row(LedgerBook book, int index, StatementLine line, LocalDate today) {
    final done = _done.contains(index);
    final selectable = !done && !_saving && StatementImport.isSelectable(line);
    final on = _selected!.contains(index);
    final day = DateLabels.day(line.occurredOn, today: today);
    final what = done ? 'Lançada' : StatementLineLabels.what(line, book);
    final note = !done && _known.contains(index) ? ' · parece já lançado' : '';
    final state = selectable ? (on ? ', marcada' : ', desmarcada') : '';
    return CajuiListRow(
      title: line.description,
      subtitle: '$what · $day$note',
      semanticLabel:
          '${line.description}, ${BrlFormatter.format(line.amount.cents)}, '
          '$what, $day$note$state',
      trailing: _trailing(index, line, on: on, selectable: selectable),
      onPressed: selectable ? () => _toggle(index) : null,
    );
  }

  Widget _trailing(
    int index,
    StatementLine line, {
    required bool on,
    required bool selectable,
  }) => Row(
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
  );

  Widget _footer() {
    final count = _selected?.length ?? 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CajuiButton(
          label: StatementLineLabels.recordLabel(count),
          expand: true,
          loading: _saving,
          onPressed: count == 0 || _saving ? null : _record,
        ),
        const SizedBox(height: CajuiSpacing.sm),
        CajuiButton(
          label: _done.isEmpty ? 'Descartar' : 'Pronto',
          variant: CajuiButtonVariant.ghost,
          expand: true,
          onPressed: _saving ? null : _leave,
        ),
      ],
    );
  }

  /// Sem nada lançado, descartar; com parte lançada, fechar sem apagar.
  void _leave() =>
      _done.isEmpty ? _vm.discard(widget.capture) : _vm.closed(widget.capture);
}
