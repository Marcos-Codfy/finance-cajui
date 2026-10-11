import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// "Por onde foi pago": uma forma de pagamento, ou duas com o valor de cada
/// (RN-204) — e, no cartão de crédito, em quantas vezes.
class PaymentSection extends StatelessWidget {
  /// Cria a seção para [draft].
  const new({
    required this.draft,
    required this.voucherOfMonth,
    required this.revision,
    required this.onPickMethod,
    required this.onToggleSplit,
    required this.onLineCents,
    required this.onPickInstallments,
    required this.onInstallmentAmount,
    this.lineError,
    super.key,
  });

  /// O rascunho.
  final EntryDraft draft;

  /// O saldo do vale, mostrado quando o vale é uma das formas.
  final Money voucherOfMonth;

  /// Muda quando os valores das linhas foram trocados **pelo app** — a
  /// proposta de divisão, "colocar o resto". O campo de valor guarda o que
  /// foi digitado, e só renasce com o valor novo quando isto muda.
  final int revision;

  /// Pede a escolha da forma de pagamento: a primeira ou a segunda.
  final void Function({required bool second}) onPickMethod;

  /// Divide em duas formas, ou volta a uma só.
  final VoidCallback onToggleSplit;

  /// Um valor de linha foi digitado.
  final void Function(int cents, {required bool second}) onLineCents;

  /// Pede a escolha do número de parcelas.
  final VoidCallback onPickInstallments;

  /// Chamado com o valor de cada parcela, quando a compra tem juros.
  final ValueChanged<int> onInstallmentAmount;

  /// O erro de campo a mostrar sob a linha que está zerada, se houver.
  final String? lineError;

  String? _helperFor(PaymentMethod? method) {
    if (method == null) return 'Sem escolher, vai como Pix';
    if (method.tender != Tender.mealVoucher) return null;
    return 'Vale do mês: ${BrlFormatter.format(voucherOfMonth.cents)}';
  }

  bool get _canBeParceled =>
      (draft.method?.kind.isCreditCard ?? false) && !draft.isSplit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CajuiSelectField(
          label: draft.isSplit ? 'Primeira forma' : 'Por onde foi pago',
          value: draft.method?.name,
          helper: _helperFor(draft.method),
          onPressed: () => onPickMethod(second: false),
        ),
        if (_canBeParceled) ..._installments(),
        if (draft.isSplit) ..._splitFields(context),
        const SizedBox(height: CajuiSpacing.sm),
        Align(
          alignment: Alignment.centerLeft,
          child: CajuiButton(
            label: draft.isSplit
                ? 'Pagar de uma forma só'
                : 'Dividir pagamento',
            variant: CajuiButtonVariant.ghost,
            size: CajuiButtonSize.compact,
            onPressed: draft.method == null ? null : onToggleSplit,
          ),
        ),
      ],
    );
  }

  /// Em quantas vezes, no cartão de crédito. A parcela nunca aparece sem o
  /// **total comprometido** ao lado (RN-313): "3x de R$ 320" esconde que são
  /// R$ 960 que já têm dono.
  List<Widget> _installments() {
    final count = draft.installmentCount;
    final total = Money.fromCents(draft.amountCents);
    final each = total.isPositive ? total.split(count).first : Money.zero;
    return [
      const SizedBox(height: CajuiSpacing.lg),
      CajuiSelectField(
        label: 'Em quantas vezes',
        value: count == 1
            ? 'À vista'
            : '${count}x de ${BrlFormatter.format(each.cents)}',
        helper: count == 1
            ? 'Conta no mês da compra, não no da fatura'
            : 'Total comprometido: ${BrlFormatter.format(total.cents)}. '
                  'Cada parcela conta no mês em que a fatura vence',
        onPressed: onPickInstallments,
      ),
      if (count > 1) ..._installmentAmount(count, total, each),
    ];
  }

  /// O valor de cada parcela, para quando o cartão cobra **juros** — que é
  /// o normal fora do "sem juros" (RN-314).
  ///
  /// Vem preenchido com o total dividido, que é o caso comum; mudar o valor
  /// é o que diz ao app que há juros, e aí ele mostra quanto são. O total
  /// da compra não muda: juros não são parte do que se comprou.
  List<Widget> _installmentAmount(int count, Money total, Money each) {
    final juros = draft.interestCents;
    return [
      const SizedBox(height: CajuiSpacing.md),
      CajuiAmountField(
        key: ValueKey(('parcela', revision, count, draft.amountCents)),
        label: 'Valor de cada parcela',
        initialCents: draft.installmentAmountCents ?? each.cents,
        onChanged: onInstallmentAmount,
      ),
      if (juros > 0) _Interest(juros: juros, count: count, total: total),
    ];
  }

  List<Widget> _splitFields(BuildContext context) {
    return [
      const SizedBox(height: CajuiSpacing.md),
      CajuiAmountField(
        key: ValueKey(('first', revision)),
        label: 'Quanto na primeira',
        initialCents: draft.firstCents,
        error: draft.firstCents <= 0 ? lineError : null,
        onChanged: (cents) => onLineCents(cents, second: false),
      ),
      const SizedBox(height: CajuiSpacing.lg),
      CajuiSelectField(
        label: 'Segunda forma',
        value: draft.secondMethod?.name,
        helper: _helperFor(draft.secondMethod),
        onPressed: () => onPickMethod(second: true),
      ),
      const SizedBox(height: CajuiSpacing.md),
      CajuiAmountField(
        key: ValueKey(('second', revision)),
        label: 'Quanto na segunda',
        initialCents: draft.secondCents,
        error: draft.firstCents > 0 && draft.secondCents <= 0
            ? lineError
            : null,
        onChanged: (cents) => onLineCents(cents, second: true),
      ),
      if (draft.unassignedCents != 0) _unassigned(context),
    ];
  }

  /// A conta ao vivo, antes de qualquer recusa: quanto falta, ou quanto
  /// passou. É informação, não erro — a pessoa ainda está digitando.
  Widget _unassigned(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final gap = BrlFormatter.format(draft.unassignedCents.abs());
    return Padding(
      padding: const EdgeInsets.only(top: CajuiSpacing.sm),
      child: Text(
        draft.unassignedCents > 0
            ? 'Faltam $gap para fechar a conta.'
            : 'As duas formas passam $gap do valor da compra.',
        style: theme.typography.caption.copyWith(
          color: theme.colors.text.muted,
        ),
      ),
    );
  }
}

/// Quanto de juros a compra tem, dito em texto e ao lado do total — nunca
/// só a parcela, que esconde o tamanho do compromisso (RN-313).
class _Interest extends StatelessWidget {
  const new({required this.juros, required this.count, required this.total});

  final int juros;
  final int count;
  final Money total;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: CajuiSpacing.xs),
      child: Text(
        'Juros: ${BrlFormatter.format(juros)} em ${count}x — o total da '
        'compra continua ${BrlFormatter.format(total.cents)}',
        style: theme.typography.caption.copyWith(
          color: theme.colors.text.muted,
        ),
      ),
    );
  }
}
