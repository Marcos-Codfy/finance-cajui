import 'package:cajui/src/features/cards/presentation/card_form_page.dart';
import 'package:cajui/src/features/cards/presentation/statement_page.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
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
    final cards = ref.watch(ledgerProvider).value?.cards ?? const [];
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
        for (final card in cards) _row(context, card),
      ],
    );
  }

  static const _noCardsYet = CajuiEmptyState(
    title: 'Nenhum cartão ainda',
    message:
        'Cadastre o cartão para pagar compras com ele. O Cajui só precisa '
        'do nome e dos dias de fechamento e de vencimento — nunca do número.',
  );

  Widget _row(BuildContext context, CreditCard card) => CajuiListRow(
    leading: const CajuiIcon(CajuiIconData.card),
    title: card.name,
    subtitle: 'fecha dia ${card.closingDay} · vence dia ${card.dueDay}',
    trailing: const CajuiIcon(CajuiIconData.chevronRight),
    semanticLabel: '${card.name}, ver a fatura',
    onPressed: () => StatementPage.open(context, card),
  );
}
