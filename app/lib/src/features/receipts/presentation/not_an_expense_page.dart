import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/receipts/application/capture.dart';
import 'package:cajui/src/features/receipts/presentation/capture_view_model.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Um comprovante que **não é despesa**: pagamento de fatura de cartão ou
/// transferência entre contas da própria pessoa (RN-756, RN-759).
///
/// Lançar um deles contaria o mesmo dinheiro duas vezes. A tela diz isso,
/// oferece registrar o pagamento da fatura — que é o que ele é — e deixa a
/// porta aberta para "é uma despesa", se a leitura errou.
class NotAnExpensePage extends ConsumerStatefulWidget {
  /// Cria a tela de [capture].
  const new({required this.capture, super.key});

  /// O comprovante lido.
  final Capture capture;

  @override
  ConsumerState<NotAnExpensePage> createState() => _NotAnExpensePageState();
}

class _NotAnExpensePageState extends ConsumerState<NotAnExpensePage> {
  CreditCard? _card;
  bool _saving = false;

  EntryProposal get _proposal => widget.capture.proposal;

  bool get _isCardPayment =>
      _proposal.documentKind.value == DocumentKind.statementPayment;

  Money? get _amount =>
      _proposal.amount.value ?? _proposal.amount.candidates.firstOrNull;

  CaptureViewModel get _capture => ref.read(captureProvider.notifier);

  /// A fatura paga vira liquidação do cartão, no mês do vencimento: o mês
  /// em que o pagamento aconteceu (RN-340).
  Future<void> _settle(CreditCard card, Money amount) async {
    setState(() => _saving = true);
    final feedback = CajuiFeedbackScope.of(context);
    final on = _proposal.occurredOn.value ?? ref.read(clockProvider).today();
    await ref
        .read(ledgerProvider.notifier)
        .settleStatement(card: card, dueMonth: on.budgetMonth, amount: amount);
    feedback.saved();
    await _capture.closed(widget.capture);
  }

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final cards = ref.watch(ledgerProvider).value?.cards ?? const [];
    final card = _card ?? (cards.length == 1 ? cards.single : null);
    return CajuiScreen(
      title: _isCardPayment ? 'Pagamento de fatura' : 'Entre contas suas',
      onBack: () => _capture.defer(widget.capture),
      footer: _footer(card),
      children: [
        Text(
          _isCardPayment
              ? 'Pagamento de fatura não é despesa: as compras do cartão já '
                    'contaram quando foram feitas. Lançar de novo contaria o '
                    'mesmo dinheiro duas vezes.'
              : 'Dinheiro que vai de uma conta sua para outra não é gasto nem '
                    'renda. Não precisa lançar.',
          style: theme.typography.body.copyWith(color: theme.colors.text.muted),
        ),
        if (_isCardPayment && cards.length > 1) ...[
          const SizedBox(height: CajuiSpacing.lg),
          _whichCard(cards, card),
        ],
      ],
    );
  }

  Widget _whichCard(List<CreditCard> cards, CreditCard? chosen) => Wrap(
    spacing: CajuiSpacing.sm,
    runSpacing: CajuiSpacing.sm,
    children: [
      for (final card in cards)
        CajuiChip(
          label: card.name,
          selected: chosen?.id == card.id,
          onSelected: (_) => setState(() => _card = card),
        ),
    ],
  );

  Widget _settleButton(CreditCard card, Money amount) => CajuiButton(
    label: 'Registrar o pagamento da fatura',
    expand: true,
    loading: _saving,
    onPressed: _saving ? null : () => _settle(card, amount),
  );

  Widget _footer(CreditCard? card) {
    final amount = _amount;
    final canSettle = _isCardPayment && card != null && amount != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canSettle) ...[
          _settleButton(card, amount),
          const SizedBox(height: CajuiSpacing.sm),
        ],
        CajuiButton(
          label: 'Não lançar',
          variant: canSettle
              ? CajuiButtonVariant.secondary
              : CajuiButtonVariant.primary,
          expand: true,
          onPressed: () => _capture.discard(widget.capture),
        ),
        CajuiButton(
          label: 'É uma despesa',
          variant: CajuiButtonVariant.ghost,
          expand: true,
          onPressed: _capture.treatAsExpense,
        ),
      ],
    );
  }
}
