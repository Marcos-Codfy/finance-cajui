import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/features/budget/application/income_service.dart';
import 'package:cajui/src/features/home/application/home_view.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O vale: o saldo que o Cajui calcula e a conferência com o app da
/// operadora (RN-123, BL-079).
///
/// O vale é outra moeda e nunca se soma ao dinheiro (RN-111). O saldo do
/// Cajui é conta — o que entrou de vale menos o que foi pago com ele —, e a
/// operadora é quem sabe de verdade: quando os dois discordam, acertar é
/// admitir o número dela. O acerto não é gasto nem renda.
class VoucherPage extends ConsumerStatefulWidget {
  /// Cria a tela.
  const new({super.key});

  /// Abre a tela.
  static Future<void> open(BuildContext context) =>
      Navigator.of(context)
          .push<void>(CajuiPageRoute(builder: (_) => const VoucherPage()));

  @override
  ConsumerState<VoucherPage> createState() => _VoucherPageState();
}

class _VoucherPageState extends ConsumerState<VoucherPage> {
  int _actual = 0;
  bool _saving = false;
  Money? _settled;

  static String _brl(Money amount) => BrlFormatter.format(amount.cents);

  Future<void> _settle() async {
    setState(() => _saving = true);
    final actual = Money.fromCents(_actual);
    await ref
        .read(incomeServiceProvider)
        .setVoucherBalance(actual, reason: 'Saldo do app da operadora');
    if (!mounted) return;
    setState(() {
      _saving = false;
      _settled = actual;
    });
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(homeViewProvider);
    final book = ref.watch(ledgerProvider).value;
    final back = Navigator.of(context).pop;
    if (view == null || book == null) {
      return CajuiScreen(
        title: 'Vale',
        onBack: back,
        children: const [CajuiSkeleton(height: 200)],
      );
    }
    final paired = ref.watch(ledgerUplinkProvider).isPaired;
    return CajuiScreen(
      title: 'Vale',
      overline: DateLabels.month(view.budget.month),
      onBack: back,
      footer: paired ? _footer() : null,
      children: [
        ..._numbers(view, book.voucher.balance),
        if (paired) ..._check(),
        ..._adjustments(book.voucherAdjustments),
      ],
    );
  }

  List<Widget> _numbers(HomeView view, Money balance) => [
    CajuiStatCard(
      label: 'Saldo do vale',
      cents: balance.cents,
      large: true,
      tone: CajuiAmountTone.accent,
      caption:
          'Pelo que está lançado: o que entrou de vale menos o que foi pago '
          'com ele. Não se soma ao dinheiro.',
    ),
    const SizedBox(height: CajuiSpacing.lg),
    CajuiStatCard(
      label: 'Vale do mês',
      cents: view.budget.voucher.cents,
      caption: '${_brl(view.budget.voucherCovered)} cobre o mercado neste mês',
      sunken: true,
    ),
  ];

  /// A conferência: o número da operadora, e o aviso de que deu certo.
  List<Widget> _check() {
    final settled = _settled;
    return [
      const CajuiSectionTitle('Conferir com a operadora'),
      Text(
        'Se o app da operadora mostra outro saldo, digite aqui. O Cajui '
        'acerta a diferença, que não conta como gasto nem como renda.',
        style: CajuiTheme.of(context).typography.body.copyWith(
          color: CajuiTheme.of(context).colors.text.muted,
        ),
      ),
      const SizedBox(height: CajuiSpacing.lg),
      if (settled != null) ...[
        CajuiNotice(
          what: 'Saldo acertado para ${_brl(settled)}.',
          intent: CajuiNoticeIntent.positive,
          onDismiss: () => setState(() => _settled = null),
        ),
        const SizedBox(height: CajuiSpacing.lg),
      ],
      CajuiAmountField(
        label: 'O app da operadora diz',
        onChanged: (cents) => setState(() => _actual = cents),
      ),
    ];
  }

  Widget _footer() => CajuiButton(
    label: 'Acertar o saldo',
    expand: true,
    loading: _saving,
    onPressed: _actual > 0 ? _settle : null,
  );

  /// Os últimos acertos: quando, e de quanto, para a pessoa ver o que o
  /// Cajui fez com o número que ela deu.
  List<Widget> _adjustments(List<VoucherAdjustment> all) {
    if (all.isEmpty) return const [];
    final recent = all.reversed.take(3);
    return [
      const CajuiSectionTitle('Acertos'),
      for (final adjustment in recent)
        CajuiListRow(
          title: DateLabels.short(adjustment.on),
          subtitle: adjustment.reason,
          trailing: CajuiAmountText(adjustment.amount.cents),
        ),
    ];
  }
}
