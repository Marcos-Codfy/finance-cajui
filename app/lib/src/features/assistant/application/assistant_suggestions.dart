import 'package:cajui/src/features/assistant/application/assistant_reply.dart';
import 'package:domain/domain.dart';

/// As sugestões da Juju: na primeira conversa, tiradas do mês (17/10/2026);
/// depois de cada resposta, as que mais fazem sentido ali (24/10/2026). Três,
/// para caber numa olhada.
abstract final class AssistantSuggestions {
  /// As de sempre: o que a Juju faz bem em qualquer mês.
  static const List<String> always = [
    'Gastei 35 no mercado',
    'Quanto sobra neste mês?',
    'Para onde foi o dinheiro deste mês?',
  ];

  static const _left = 'Quanto sobra neste mês?';
  static const _where = 'Para onde foi o dinheiro deste mês?';
  static const _bills = 'O que falta pagar?';

  /// As sugestões de [month] em [finances] para a primeira conversa;
  /// [cardIds] são os cartões.
  static List<String> of(
    Finances? finances,
    BudgetMonth month, {
    Set<String> cardIds = const {},
  }) {
    final open = _openBills(finances, month, cardIds);
    if (open.isEmpty) return always;
    return [_bills, 'Paguei ${open.first}', _left];
  }

  /// As sugestões depois da última de [exchanges]: o que costuma vir em
  /// seguida do assunto dela, sem repetir pergunta que a conversa já teve.
  /// Sem resposta de verdade — a primeira conversa, uma falha, a resposta de
  /// formato fixo —, não há o que sugerir.
  static List<String> after(
    List<(String question, AssistantReply reply)> exchanges,
    Finances? finances,
    BudgetMonth month, {
    Set<String> cardIds = const {},
  }) {
    if (exchanges.isEmpty) return const [];
    final (question, reply) = exchanges.last;
    if (reply is! AssistantAnswered || reply.isFallback) return const [];
    final open = _openBills(finances, month, cardIds);
    final asked = {for (final (q, _) in exchanges) _key(q)};
    final pool = [
      ..._next(question, recorded: reply.actions.isNotEmpty),
      if (open.isNotEmpty) 'Paguei ${open.first}',
      _left,
      _where,
      _bills,
    ];
    return {
      for (final suggestion in pool)
        if (!asked.contains(_key(suggestion))) suggestion,
    }.take(3).toList();
  }

  /// O que vem depois de [question]: quem viu a sobra quer saber para onde
  /// foi; quem viu para onde foi, quanto sobra; quem lançou, como ficou o mês.
  static List<String> _next(String question, {required bool recorded}) {
    final text = question.toLowerCase();
    if (recorded) return const [_left, _bills];
    if (text.contains('sobr') ||
        text.contains('faltam') ||
        text.contains('saldo')) {
      return const [_where, _bills];
    }
    if (text.contains('onde') || text.contains('categoria')) {
      return const [_left, _bills];
    }
    if (text.contains('pagar') || text.contains('conta')) {
      return const [_left, _where];
    }
    return const [];
  }

  static String _key(String text) => text.toLowerCase().trim();

  static List<String> _openBills(
    Finances? finances,
    BudgetMonth month,
    Set<String> cardIds,
  ) => finances == null
      ? const []
      : [
          for (final bill in MonthBills.of(finances, month, cardIds: cardIds))
            if (!bill.paid) bill.line.name,
        ];
}
