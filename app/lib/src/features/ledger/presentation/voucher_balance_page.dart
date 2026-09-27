import 'package:cajui/src/features/budget/application/income_service.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Corrige o saldo do vale para bater com o da operadora (RN-123).
class VoucherBalancePage extends ConsumerStatefulWidget {
  /// Cria a tela de correção do saldo.
  const new({super.key});

  /// Abre a tela.
  static Future<void> open(BuildContext context) {
    return Navigator.of(context)
        .push<void>(CajuiPageRoute(builder: (_) => const VoucherBalancePage()));
  }

  @override
  ConsumerState<VoucherBalancePage> createState() => _VoucherBalancePageState();
}

class _VoucherBalancePageState extends ConsumerState<VoucherBalancePage> {
  int? _typedCents;
  bool _saving = false;

  Future<void> _save(int cents) async {
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final feedback = CajuiFeedbackScope.of(context);
    await ref
        .read(incomeServiceProvider)
        .setVoucherBalance(
          Money.fromCents(cents),
          reason: 'Saldo informado a partir da operadora',
        );
    feedback.saved();
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final current = ref.watch(ledgerProvider).value?.voucher.balance.cents ?? 0;
    final cents = _typedCents ?? current;
    return CajuiScreen(
      title: 'Saldo do vale',
      onBack: Navigator.of(context).pop,
      footer: CajuiButton(
        label: 'Guardar saldo',
        expand: true,
        loading: _saving,
        onPressed: () => _save(cents),
      ),
      children: [
        Text(
          'O Cajui não fala com a operadora do vale. Se o saldo daqui não '
          'bate com o do cartão, informe o saldo de verdade. A diferença '
          'fica registrada como ajuste: não vira despesa nem renda.',
          style: theme.typography.body.copyWith(color: theme.colors.text.muted),
        ),
        const SizedBox(height: CajuiSpacing.xl),
        CajuiAmountField(
          label: 'Saldo que a operadora mostra',
          initialCents: current,
          onChanged: (value) => setState(() => _typedCents = value),
        ),
      ],
    );
  }
}
