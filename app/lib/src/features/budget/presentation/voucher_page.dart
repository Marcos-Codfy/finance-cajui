import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/core/navigation/coordinator_access.dart';
import 'package:cajui/src/features/budget/application/income_service.dart';
import 'package:cajui/src/features/home/application/home_view.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
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

  @override
  ConsumerState<VoucherPage> createState() => _VoucherPageState();
}

class _VoucherPageState extends ConsumerState<VoucherPage> {
  /// O que a pessoa digitou; `null` enquanto o campo mostra o saldo do
  /// Cajui, que é de onde ele parte.
  int? _typed;
  bool _saving = false;
  Money? _settled;

  static String _brl(Money amount) => BrlFormatter.format(amount.cents);

  /// O saldo que a operadora mostra, como está no campo.
  Money _actual(LedgerBook book) =>
      Money.fromCents(_typed ?? book.voucher.balance.cents);

  Future<void> _settle(Money actual) async {
    setState(() => _saving = true);
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
    final back = context.back;
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
      // A rolagem em profundidade e a entrada de câmera (ADR-028).
      depth: true,
      cinematic: true,
      footer: paired ? _footer(book) : null,
      children: [
        ..._numbers(view, book),
        if (paired) ..._check(book),
        ..._adjustments(book.voucherAdjustments),
      ],
    );
  }

  List<Widget> _numbers(HomeView view, LedgerBook book) => [
    CajuiStatCard(
      label: 'Saldo do vale',
      cents: book.voucher.balance.cents,
      large: true,
      tone: CajuiAmountTone.accent,
      caption: _balanceCaption(book),
    ),
    const SizedBox(height: CajuiSpacing.lg),
    CajuiStatCard(
      label: 'Vale do mês',
      cents: view.budget.voucher.cents,
      caption: '${_brl(view.budget.voucherCovered)} cobre o mercado neste mês',
      sunken: true,
    ),
  ];

  /// O que o saldo quer dizer, sem afirmar o que o livro não sabe: zero
  /// sem crédito nenhum não é o mesmo que zero depois de gastar tudo.
  static String _balanceCaption(LedgerBook book) {
    final voucher = book.voucher;
    if (voucher.overdrawn.isPositive) {
      return 'Os pagamentos no vale passaram ${_brl(voucher.overdrawn)} do '
          'que entrou, pelo que está lançado. Confira com a operadora abaixo.';
    }
    if (voucher.balance.isPositive) {
      return 'Pelo que está lançado: o que entrou de vale menos o que foi '
          'pago com ele. Não se soma ao dinheiro.';
    }
    final credited =
        book.receipts.any((r) => r.tender == Tender.mealVoucher) ||
        book.voucherAdjustments.isNotEmpty;
    return credited
        ? 'O vale foi todo usado, pelo que está lançado.'
        : 'Ainda não há crédito do vale registrado. Se a operadora mostra '
              'saldo, acerte abaixo.';
  }

  /// A conferência: o número da operadora, e o aviso de que deu certo. O
  /// campo parte do saldo do Cajui, e a chave o mantém o mesmo quando o
  /// aviso aparece acima dele — recriado, ele voltava a zero e mostrava um
  /// número diferente do que o botão acertaria.
  List<Widget> _check(LedgerBook book) {
    final settled = _settled;
    return [
      const CajuiSectionTitle('Conferir com a operadora'),
      Text(
        'Se o app da operadora mostra outro saldo, digite aqui. O Cajui '
        'acerta a diferença, que não conta como gasto nem como renda.',
        style: CajuiTheme.of(context).typography.body
            .copyWith(color: CajuiTheme.of(context).colors.text.muted),
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
        key: const ValueKey('saldo-da-operadora'),
        label: 'O app da operadora diz',
        initialCents: book.voucher.balance.cents,
        onChanged: (cents) => setState(() => _typed = cents),
      ),
    ];
  }

  /// Liga quando o número do campo dá um acerto — inclusive para zerar,
  /// o caso mais comum no fim do mês (RN-123).
  Widget _footer(LedgerBook book) {
    final actual = _actual(book);
    final differs = !book.voucher.adjustmentTo(actual).isZero;
    return CajuiButton(
      label: 'Acertar o saldo',
      expand: true,
      loading: _saving,
      onPressed: differs ? () => _settle(actual) : null,
    );
  }

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
