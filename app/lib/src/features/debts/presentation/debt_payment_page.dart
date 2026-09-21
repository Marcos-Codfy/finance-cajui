import 'package:cajui/src/core/errors/error_notice.dart';
import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/features/debts/application/debts_service.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/ledger/presentation/date_section.dart';
import 'package:cajui/src/features/ledger/presentation/option_picker_page.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Registrar o pagamento da parcela do mês (RN-520).
///
/// O pagamento **é um lançamento** como outro qualquer: entra no bloco de
/// dívidas, sai da moeda por onde foi pago e conta no mês em que aconteceu.
/// Esta tela só pergunta o que falta — por onde e quando.
class DebtPaymentPage extends ConsumerStatefulWidget {
  /// Cria a tela de pagamento de [debt].
  const new({required this.debt, super.key});

  /// A dívida cuja parcela vai ser paga.
  final Debt debt;

  /// Abre a tela.
  static Future<void> open(BuildContext context, Debt debt) {
    return Navigator.of(
      context,
    ).push<void>(CajuiPageRoute(builder: (_) => DebtPaymentPage(debt: debt)));
  }

  @override
  ConsumerState<DebtPaymentPage> createState() => _DebtPaymentPageState();
}

class _DebtPaymentPageState extends ConsumerState<DebtPaymentPage> {
  PaymentMethod? _method;
  late LocalDate _paidOn = ref.read(clockProvider).today();
  PresentedError? _problem;
  bool _saving = false;

  Debt get _debt => widget.debt;

  /// O vale alimentação não paga dívida: é outra moeda, e só compra comida
  /// (RN-111, RN-113). Cartão de crédito também fica de fora — pagar dívida
  /// com cartão é outra dívida, e isso ainda não está descrito.
  List<PaymentMethod> _methods(LedgerBook book) => [
    ...book.paymentMethods.where((method) => method.tender == Tender.cash),
  ];

  Future<void> _pickMethod(LedgerBook book) async {
    final picked = await OptionPickerPage.open<PaymentMethod>(
      context,
      title: 'Por onde foi pago',
      options: _methods(book),
      labelOf: (method) => method.name,
      selected: _method,
    );
    if (picked != null) setState(() => _method = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final feedback = CajuiFeedbackScope.of(context);
    final result = await ref
        .read(debtsServiceProvider)
        .payInstallment(_debt, method: _method!, on: _paidOn);
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

  String get _explanation {
    final amount = BrlFormatter.format(_debt.installmentAmount.cents);
    final number = _debt.paidInstallments + 1;
    return 'Parcela $number de ${_debt.totalInstallments}, de $amount. Ela '
        'vira um lançamento do bloco de dívidas, no dia em que foi paga.';
  }

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(ledgerProvider).value;
    if (book == null) return const SizedBox.shrink();
    final theme = CajuiTheme.of(context);
    return CajuiScreen(
      title: 'Pagar parcela',
      onBack: Navigator.of(context).pop,
      footer: _footer(),
      children: [
        Text(
          _explanation,
          style: theme.typography.body.copyWith(color: theme.colors.text.muted),
        ),
        const SizedBox(height: CajuiSpacing.xl),
        CajuiSelectField(
          label: 'Por onde foi pago',
          value: _method?.name,
          onPressed: () => _pickMethod(book),
        ),
        const SizedBox(height: CajuiSpacing.lg),
        DateSection(
          selected: _paidOn,
          today: ref.watch(clockProvider).today(),
          onChanged: (day) => setState(() => _paidOn = day),
        ),
      ],
    );
  }

  Widget _footer() {
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
          label: 'Registrar pagamento',
          expand: true,
          loading: _saving,
          onPressed: _method == null ? null : _save,
        ),
      ],
    );
  }
}
