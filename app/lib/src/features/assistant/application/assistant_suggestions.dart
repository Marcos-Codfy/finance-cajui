import 'package:domain/domain.dart';

/// As sugestões da primeira conversa com a Juju, tiradas do mês (17/10/2026):
/// com conta aberta, "O que falta pagar?" e "Paguei a <conta que vence
/// primeiro>"; sem, as de sempre. Três, para caber numa olhada.
abstract final class AssistantSuggestions {
  /// As de sempre: o que a Juju faz bem em qualquer mês.
  static const List<String> always = [
    'Gastei 35 no mercado',
    'Quanto sobra neste mês?',
    'Para onde foi o dinheiro deste mês?',
  ];

  /// As sugestões de [month] em [finances]; [cardIds] são os cartões.
  static List<String> of(
    Finances? finances,
    BudgetMonth month, {
    Set<String> cardIds = const {},
  }) {
    if (finances == null) return always;
    final open = [
      for (final bill in MonthBills.of(finances, month, cardIds: cardIds))
        if (!bill.paid) bill.line.name,
    ];
    if (open.isEmpty) return always;
    return ['O que falta pagar?', 'Paguei ${open.first}', always[1]];
  }
}
