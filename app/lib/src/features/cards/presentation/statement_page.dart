import 'package:cajui/src/core/format/date_labels.dart';
import 'package:cajui/src/core/presentation/loading_page.dart';
import 'package:cajui/src/features/cards/application/statement_view.dart';
import 'package:cajui/src/features/cards/presentation/card_form_page.dart';
import 'package:cajui/src/features/cards/presentation/statement_section.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/today_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A fatura de um cartão: uma **visão** das compras feitas nele, e nunca uma
/// despesa (RN-330).
///
/// Mostra a fatura que já fechou e a que está aberta. Pagar a fatura é uma
/// liquidação: as compras já contaram quando foram feitas, então o pagamento
/// não acrescenta nada às despesas do mês (RN-340).
class StatementPage extends ConsumerWidget {
  /// Cria a tela da fatura de [card].
  const new({required this.card, super.key});

  /// O cartão.
  final CreditCard card;

  /// Abre a tela.
  static Future<void> open(BuildContext context, CreditCard card) {
    return Navigator.of(context)
        .push<void>(CajuiPageRoute(builder: (_) => StatementPage(card: card)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(ledgerProvider).value;
    if (book == null) return LoadingPage(title: this.card.name);
    final today = ref.watch(todayProvider);
    final card = _latestIn(book);
    final views = StatementView.current(book, card, today);
    final nothingYet = views.every((view) => view.statement.total.isZero);
    final limit = StatementView.limitOf(book, card, today);
    return CajuiScreen(
      title: card.name,
      overline: 'fecha dia ${card.closingDay} · vence dia ${card.dueDay}',
      onBack: Navigator.of(context).pop,
      children: [
        if (limit != null) ...[
          _limitCard(limit),
          const SizedBox(height: CajuiSpacing.lg),
        ],
        if (nothingYet) _noPurchasesYet,
        for (final view in views)
          if (!view.statement.total.isZero)
            StatementSection(
              view: view,
              book: book,
              title: _titleOf(view, today),
              onSettle: (amount) => _settle(ref, view, amount),
            ),
        ..._edit(context, card),
      ],
    );
  }

  /// A versão mais nova do cartão: alterado pela tela de edição, o nome e o
  /// limite mudam aqui sem precisar voltar e abrir a fatura de novo.
  CreditCard _latestIn(LedgerBook book) =>
      book.cards.firstWhere((each) => each.id == card.id, orElse: () => card);

  /// O caminho para alterar o cartão — o limite muda com o banco.
  static List<Widget> _edit(BuildContext context, CreditCard card) => [
    const SizedBox(height: CajuiSpacing.lg),
    CajuiButton(
      label: 'Alterar cartão',
      variant: CajuiButtonVariant.ghost,
      onPressed: () => CardFormPage.open(context, card: card),
    ),
  ];

  /// O limite livre, com o medidor do que está tomado (RN-305). Passar do
  /// limite não vira alarme: o medidor enche, e a frase diz quanto passou.
  static Widget _limitCard(CardLimitUsage usage) {
    final limit = BrlFormatter.format(usage.limit.cents);
    final taken = BrlFormatter.format(usage.taken.cents);
    final over = BrlFormatter.format(usage.exceeded.cents);
    return CajuiStatCard(
      label: 'Limite livre',
      cents: usage.available.cents,
      meter: usage.fraction,
      caption: usage.exceeded.isPositive
          ? 'O tomado passou $over do limite de $limit. Conta as faturas '
                'em aberto e as parcelas por vencer.'
          : '$taken tomados de $limit: faturas em aberto e parcelas por '
                'vencer.',
    );
  }

  /// O cajuí: a fatura que ainda não começou.
  static const _noPurchasesYet = CajuiEmptyState(
    illustration: CajuiCerradoArt(CajuiCerrado.cashew),
    title: 'Nenhuma compra neste cartão',
    message:
        'Ao lançar uma despesa, escolha este cartão em "Por onde foi pago". '
        'A compra conta na categoria dela, no dia em que foi feita; a fatura '
        'aparece aqui, calculada.',
  );

  Future<void> _settle(WidgetRef ref, StatementView view, Money amount) => ref
      .read(ledgerProvider.notifier)
      .settleStatement(
        card: card,
        dueMonth: view.cycle.dueMonth,
        amount: amount,
      );

  static String _titleOf(StatementView view, LocalDate today) {
    final due = DateLabels.long(view.cycle.dueOn);
    return view.isClosedOn(today)
        ? 'Fatura fechada · vence em $due'
        : 'Fatura aberta · fecha em '
              '${DateLabels.long(view.cycle.closesOn)}, vence em $due';
  }
}
