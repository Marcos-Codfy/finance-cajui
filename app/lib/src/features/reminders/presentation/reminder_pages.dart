import 'dart:async';

import 'package:cajui/src/features/budget/presentation/my_bills_page.dart';
import 'package:cajui/src/features/cards/presentation/cards_page.dart';
import 'package:cajui/src/features/debts/presentation/debts_page.dart';
import 'package:cajui/src/features/reminders/application/reminder_routes.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// A tela que cada lembrete tocado abre, por cima do que estiver aberto
/// (RN-849, RN-1087): a conta abre Minhas contas, a parcela abre as
/// dívidas, a fatura abre os cartões — nunca o painel genérico.
abstract final class ReminderPages {
  /// Abre a tela do pedido [route], se ele é de um lembrete. Devolve se
  /// abriu: outro pedido — a revisão de domingo — fica com quem o conhece.
  static bool open(BuildContext context, String route) {
    final target = ReminderRoutes.targetOf(route);
    if (target == null) return false;
    unawaited(switch (target) {
      ReminderTarget.bills => MyBillsPage.open(context),
      ReminderTarget.debts => DebtsPage.open(context),
      ReminderTarget.cards => CardsPage.open(context),
    });
    return true;
  }
}
