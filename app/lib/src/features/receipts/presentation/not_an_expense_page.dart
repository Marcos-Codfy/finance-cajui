import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/core/navigation/coordinator_access.dart';
import 'package:cajui/src/features/cards/presentation/cards_coordinator.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/receipts/application/capture.dart';
import 'package:cajui/src/features/receipts/application/capture_route.dart';
import 'package:cajui/src/features/receipts/presentation/capture_view_model.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Um comprovante que **não é despesa**: pagamento de fatura de cartão ou
/// transferência entre contas da própria pessoa (RN-756, RN-759).
///
/// Lançar um deles contaria o mesmo dinheiro duas vezes. A tela diz isso e,
/// na fatura, leva à tela do cartão: é lá que o domínio mostra **qual**
/// fatura está aberta e quanto falta — o mês do pagamento nem sempre é o da
/// fatura. Quando só a IA achou que não era compra, a tela pergunta, e "É
/// uma despesa" fica à mão (RN-757).
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
  bool _visited = false;

  EntryProposal get _proposal => widget.capture.proposal;

  bool get _isCardPayment =>
      CaptureRoute.kindOf(_proposal) == DocumentKind.statementPayment;

  bool get _inDoubt => _proposal.documentKind.value == null;

  CaptureViewModel get _vm => ref.read(captureProvider.notifier);

  Future<void> _openStatement(CreditCard card) async {
    await context.coordinator(cardsCoordinatorProvider).openStatement(card);
    if (mounted) setState(() => _visited = true);
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(ledgerProvider).value?.cards ?? const [];
    final card = _card ?? (cards.length == 1 ? cards.single : null);
    return CajuiScreen(
      title: _title,
      onBack: () => _vm.defer(widget.capture),
      footer: _footer(card),
      children: [
        _text(context),
        if (_isCardPayment && cards.length > 1) ...[
          const SizedBox(height: CajuiSpacing.lg),
          _whichCard(cards, card),
        ],
      ],
    );
  }

  String get _title {
    final title = _isCardPayment ? 'Pagamento de fatura' : 'Entre contas suas';
    return _inDoubt ? '$title?' : title;
  }

  Widget _text(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final doubt = _inDoubt ? 'Li isto assim, mas não tenho certeza. ' : '';
    final why = _isCardPayment
        ? 'Pagamento de fatura não é despesa: as compras do cartão já '
              'contaram quando foram feitas. Lançar de novo contaria o mesmo '
              'dinheiro duas vezes.'
        : 'Dinheiro que vai de uma conta sua para outra não é gasto nem '
              'renda. Não precisa lançar.';
    return Text(
      '$doubt${_read()}$why',
      style: theme.typography.body.copyWith(color: theme.colors.text.muted),
    );
  }

  /// O que foi lido, para a pessoa conferir antes de abrir a fatura.
  String _read() {
    final amount = _proposal.amount.value;
    if (amount == null) return '';
    final on = _proposal.occurredOn.value;
    final today = ref.read(clockProvider).today();
    final day = on == null ? '' : ', ${DateLabels.day(on, today: today)}';
    return 'Li ${BrlFormatter.format(amount.cents)}$day. ';
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

  Widget _footer(CreditCard? card) {
    final canOpen = _isCardPayment && card != null && !_visited;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (canOpen)
          _primary(
            'Ver a fatura e registrar o pagamento',
            () => _openStatement(card),
          ),
        if (_visited) _primary('Pronto', () => _vm.closed(widget.capture)),
        CajuiButton(
          label: 'Não lançar',
          variant: canOpen || _visited
              ? CajuiButtonVariant.secondary
              : CajuiButtonVariant.primary,
          expand: true,
          onPressed: () => _vm.discard(widget.capture),
        ),
        _asExpense(),
      ],
    );
  }

  /// "É uma despesa": discreto quando a leitura teve certeza, à mão quando
  /// não teve.
  Widget _asExpense() => CajuiButton(
    label: 'É uma despesa',
    variant: _inDoubt ? CajuiButtonVariant.secondary : CajuiButtonVariant.ghost,
    expand: true,
    onPressed: _vm.treatAsExpense,
  );

  Widget _primary(String label, VoidCallback onPressed) => Padding(
    padding: const EdgeInsets.only(bottom: CajuiSpacing.sm),
    child: CajuiButton(label: label, expand: true, onPressed: onPressed),
  );
}
