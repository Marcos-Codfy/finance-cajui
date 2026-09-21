import 'package:cajui/src/core/errors/error_notice.dart';
import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/budget/application/month_closing.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fechar o mês que terminou (RN-440).
///
/// O fechamento é um retrato: mudar uma faixa em outubro não altera o
/// setembro que já fechou. Falta no mês fechado **não vira dívida** e não é
/// descontada do mês seguinte por conta própria — fica dita, e o que fazer
/// com ela é decisão de quem usa (RN-443).
class MonthClosePage extends ConsumerStatefulWidget {
  /// Cria a tela de fechamento.
  const new({super.key});

  /// Abre a tela.
  static Future<void> open(BuildContext context) {
    return Navigator.of(context)
        .push<void>(CajuiPageRoute(builder: (_) => const MonthClosePage()));
  }

  @override
  ConsumerState<MonthClosePage> createState() => _MonthClosePageState();
}

class _MonthClosePageState extends ConsumerState<MonthClosePage> {
  PresentedError? _problem;
  bool _saving = false;

  Future<void> _close(BudgetMonth month) async {
    setState(() => _saving = true);
    final feedback = CajuiFeedbackScope.of(context);
    final result = await ref.read(monthClosingProvider).close(month);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _problem = switch (result) {
        Ok() => null,
        Err(:final failure) => FailurePresenter.present(failure),
      };
    });
    if (result.isOk) feedback.saved();
  }

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(ledgerProvider).value;
    if (book == null) return const SizedBox.shrink();
    final month = ref.watch(closableMonthProvider);
    final close = book.closeOf(month);
    return CajuiScreen(
      title: 'Fechar o mês',
      onBack: Navigator.of(context).pop,
      footer: close == null ? _footer(month) : null,
      children: [
        CajuiStatCard(
          label: DateLabels.month(month),
          cents: (close?.cashResult ?? book.cashResultIn(month)).cents,
          large: true,
          tone: _toneOf(close?.cashResult ?? book.cashResultIn(month)),
          caption: 'Renda que entrou menos despesas em dinheiro do mês',
        ),
        const SizedBox(height: CajuiSpacing.lg),
        _Explanation(close: close),
      ],
    );
  }

  static CajuiAmountTone _toneOf(Money result) =>
      result.isNegative ? CajuiAmountTone.shortfall : CajuiAmountTone.positive;

  Widget _footer(BudgetMonth month) {
    final problem = _problem;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (problem != null) ...[
          ErrorNotice(
            error: problem,
            onAction: (_) => setState(() => _problem = null),
          ),
          const SizedBox(height: CajuiSpacing.md),
        ],
        CajuiButton(
          label: 'Fechar ${DateLabels.month(month)}',
          expand: true,
          loading: _saving,
          onPressed: () => _close(month),
        ),
      ],
    );
  }
}

/// O que o fechamento quer dizer, antes e depois de ele existir.
class _Explanation extends StatelessWidget {
  const new({required this.close});

  final MonthClose? close;

  String get _text {
    final done = close;
    if (done == null) {
      return 'Fechar guarda este número do jeito que está hoje. Depois disso, '
          'mudar o plano não mexe mais neste mês. Se um lançamento atrasado '
          'aparecer, o Cajui guarda uma revisão, sem apagar a anterior.';
    }
    final when = DateLabels.long(done.closedOn);
    if (done.revision == 1) {
      return 'Fechado em $when. Falta no mês fechado não vira dívida nem é '
          'descontada do mês seguinte: o que fazer com ela é sua decisão.';
    }
    return 'Revisão ${done.revision}, de $when: um lançamento com data neste '
        'mês entrou depois do fechamento. A revisão anterior continua '
        'guardada.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Text(
      _text,
      style: theme.typography.body.copyWith(color: theme.colors.text.muted),
    );
  }
}
