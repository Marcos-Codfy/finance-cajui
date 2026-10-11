import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_notice.dart';
import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/ledger/application/today_controller.dart';
import 'package:cajui/src/features/ledger/presentation/date_section.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Registrar que o dinheiro de uma compra voltou, inteiro ou em parte
/// (RN-209 a RN-211).
///
/// A tela já abre com o que ainda pode voltar: devolução inteira é o caso
/// comum, e sai em um toque. O limite quem confere é o domínio (RN-210).
class ReversalPage extends ConsumerStatefulWidget {
  /// Cria a tela para estornar [entry].
  const new({required this.entry, super.key});

  /// A compra de onde o dinheiro voltou.
  final Entry entry;

  /// Abre a tela.
  static Future<void> open(BuildContext context, Entry entry) {
    return Navigator.of(context)
        .push<void>(CajuiPageRoute(builder: (_) => ReversalPage(entry: entry)));
  }

  @override
  ConsumerState<ReversalPage> createState() => _ReversalPageState();
}

class _ReversalPageState extends ConsumerState<ReversalPage> {
  late String _methodId = _firstReversible;
  late int _cents = _remaining(_methodId).cents;
  late LocalDate _on = ref.read(clockProvider).today();
  PresentedError? _problem;
  bool _saving = false;

  /// Sobe quando o app troca o valor, para o campo renascer com ele.
  int _revision = 0;

  LedgerBook get _book => ref.read(ledgerProvider).requireValue;

  Money _remaining(String methodId) =>
      _book.reversibleOn(widget.entry, methodId);

  /// A primeira forma de pagamento que ainda tem o que voltar.
  String get _firstReversible => widget.entry.paymentLines
      .map((line) => line.paymentMethodId)
      .firstWhere(
        (id) => _remaining(id).isPositive,
        orElse: () => widget.entry.paymentLines.first.paymentMethodId,
      );

  void _setAmount(int cents) => setState(() {
    _cents = cents;
    _problem = null;
    _revision++;
  });

  Future<void> _save() async {
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final feedback = CajuiFeedbackScope.of(context);
    final result = await ref
        .read(ledgerProvider.notifier)
        .reverse(
          entry: widget.entry,
          paymentMethodId: _methodId,
          amount: Money.fromCents(_cents),
          occurredOn: _on,
        );
    if (!mounted) return;
    if (result.failureOrNull case final failure?) {
      setState(() {
        _saving = false;
        _problem = FailurePresenter.present(failure);
      });
      return;
    }
    feedback.saved();
    navigator.pop();
  }

  /// As saídas do `E-ENTRY-04`: estornar o que resta, ou só corrigir o valor.
  void _resolve(ErrorCode code, int action) {
    if (code == ErrorCode.entry04 && action == 0) {
      return _setAmount(_remaining(_methodId).cents);
    }
    setState(() => _problem = null);
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: CajuiSpacing.lg);
    final isSplit = widget.entry.paymentLines.length > 1;
    return CajuiScreen(
      title: 'Registrar estorno',
      onBack: Navigator.of(context).pop,
      footer: _footer(),
      children: [
        _Explanation(entry: widget.entry),
        gap,
        if (isSplit) ...[_whichMethod(), gap],
        CajuiAmountField(
          key: ValueKey(('reversal', _methodId, _revision)),
          label: 'Quanto voltou',
          initialCents: _cents,
          onChanged: (cents) => setState(() => _cents = cents),
        ),
        gap,
        DateSection(
          selected: _on,
          today: ref.watch(todayProvider),
          onChanged: (day) => setState(() => _on = day),
        ),
      ],
    );
  }

  /// Em pagamento dividido, por onde o dinheiro voltou: o estorno volta pela
  /// mesma forma de pagamento da linha (RN-211).
  Widget _whichMethod() => Wrap(
    spacing: CajuiSpacing.sm,
    runSpacing: CajuiSpacing.sm,
    children: [
      for (final line in widget.entry.paymentLines)
        CajuiChip(
          label: 'Voltou por ${_book.methodOf(line.paymentMethodId).name}',
          selected: _methodId == line.paymentMethodId,
          onSelected: (_) {
            _methodId = line.paymentMethodId;
            _setAmount(_remaining(_methodId).cents);
          },
        ),
    ],
  );

  Widget _footer() {
    final problem = _problem;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (problem != null) ...[
          ErrorNotice(
            error: problem,
            onAction: (index) => _resolve(problem.code, index),
          ),
          const SizedBox(height: CajuiSpacing.md),
        ],
        CajuiButton(
          label: 'Registrar estorno',
          expand: true,
          loading: _saving,
          onPressed: _cents > 0 ? _save : null,
        ),
      ],
    );
  }
}

class _Explanation extends StatelessWidget {
  const new({required this.entry});

  final Entry entry;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Text(
      'O estorno não mexe na compra de "${entry.description}": ele desconta '
      'do gasto no mês em que o dinheiro voltou, e volta pela mesma forma de '
      'pagamento.',
      style: theme.typography.body.copyWith(color: theme.colors.text.muted),
    );
  }
}
