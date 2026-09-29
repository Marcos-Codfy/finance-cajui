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

  /// Há mais gasto lançado no vale do que saldo (RN-124): o saldo daqui
  /// parou em zero, e o que a pessoa informar passa a valer.
  static List<Widget> _overdrawnNotice(Money overdrawn) => [
    CajuiNotice(
      intent: CajuiNoticeIntent.info,
      what:
          'O vale tem ${BrlFormatter.format(overdrawn.cents)} lançados '
          'além do saldo.',
      meaning:
          'Informe abaixo o saldo que a operadora mostra: ele passa a '
          'valer, e a diferença fica registrada como ajuste.',
    ),
    const SizedBox(height: CajuiSpacing.lg),
  ];

  static Widget _explanation(CajuiThemeData theme) => Text(
    'O Cajui não fala com a operadora do vale. Se o saldo daqui não bate '
    'com o do cartão, informe o saldo de verdade. A diferença fica '
    'registrada como ajuste: não vira despesa nem renda.',
    style: theme.typography.body.copyWith(color: theme.colors.text.muted),
  );

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final voucher = ref.watch(ledgerProvider).value?.voucher;
    final current = voucher?.balance.cents ?? 0;
    final overdrawn = voucher?.overdrawn ?? Money.zero;
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
        if (overdrawn.isPositive) ..._overdrawnNotice(overdrawn),
        _explanation(theme),
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
