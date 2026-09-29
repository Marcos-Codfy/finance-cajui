import 'package:cajui/src/features/cards/application/statement_view.dart';
import 'package:cajui/src/features/cards/presentation/card_form_page.dart';
import 'package:cajui/src/features/cards/presentation/statement_page.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Os cartões de crédito cadastrados, e a porta para a fatura de cada um.
///
/// No Cajui o cartão é **por onde se paga**, nunca o que se gastou: a compra
/// conta na categoria dela, no dia em que foi feita, e a fatura é só uma
/// visão calculada das compras (RN-301, RN-330).
class CardsPage extends ConsumerWidget {
  /// Cria a tela de cartões.
  const new({super.key});

  /// Abre a tela.
  static Future<void> open(BuildContext context) {
    return Navigator.of(context)
        .push<void>(CajuiPageRoute(builder: (_) => const CardsPage()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(ledgerProvider).value;
    final cards = book?.cards ?? const <CreditCard>[];
    final today = ref.watch(clockProvider).today();
    return CajuiScreen(
      title: 'Cartões de crédito',
      onBack: Navigator.of(context).pop,
      footer: CajuiButton(
        label: 'Cadastrar cartão',
        icon: CajuiIconData.plus,
        expand: true,
        onPressed: () => CardFormPage.open(context),
      ),
      children: [
        if (cards.isEmpty) _noCardsYet,
        for (final card in cards)
          _row(context, card, _freeOn(book, card, today)),
      ],
    );
  }

  static const _noCardsYet = CajuiEmptyState(
    title: 'Nenhum cartão ainda',
    message:
        'Cadastre o cartão para pagar compras com ele. O Cajui só precisa '
        'do nome e dos dias de fechamento e de vencimento — nunca do número.',
  );

  /// O limite livre de [card], já em texto; vazio quando o cartão não tem
  /// limite informado.
  static String _freeOn(LedgerBook? book, CreditCard card, LocalDate today) {
    if (book == null) return '';
    final usage = StatementView.limitOf(book, card, today);
    if (usage == null) return '';
    return ' · ${BrlFormatter.format(usage.available.cents)} livres';
  }

  Widget _row(BuildContext context, CreditCard card, String free) =>
      CajuiListRow(
        leading: const CajuiIcon(CajuiIconData.card),
        title: card.name,
        subtitle:
            'fecha dia ${card.closingDay} · vence dia ${card.dueDay}$free',
        trailing: const CajuiIcon(CajuiIconData.chevronRight),
        semanticLabel: '${card.name}, ver a fatura',
        onPressed: () => StatementPage.open(context, card),
      );
}
