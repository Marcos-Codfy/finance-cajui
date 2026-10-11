import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/reminders/reminder_target.dart';
import 'package:meta/meta.dart';

/// Uma coisa que vence numa data e ainda não foi paga: a conta de outubro, a
/// parcela 6 do carnê, a fatura de novembro (RN-1080).
///
/// É o que os três calendários — contas, dívidas e cartões — têm em comum, e
/// é só disso que o lembrete precisa para ser escrito.
@immutable
final class DueItem {
  /// Cria o item.
  const new({
    required this.target,
    required this.id,
    required this.name,
    required this.amount,
    required this.dueOn,
    this.detail,
  });

  /// De que assunto é: conta, parcela ou fatura.
  final ReminderTarget target;

  /// O identificador da linha, da dívida ou do cartão.
  final String id;

  /// Como a pessoa chama: "Aluguel", "Carnê da loja", "Cartão final 4821".
  final String name;

  /// Quanto vence.
  final Money amount;

  /// O dia do vencimento.
  final LocalDate dueOn;

  /// O que mais ajuda a reconhecer: "Parcela 6 de 10". Nulo quando não há.
  final String? detail;

  /// A chave do vencimento: a mesma nos dois momentos do lembrete. É por ela
  /// que o aparelho sabe que já avisou deste vencimento (RN-1086).
  String get eventKey => '${target.name}:$id:$dueOn';
}
