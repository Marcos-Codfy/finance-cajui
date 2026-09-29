import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// A fatura de um cartão num ciclo, como a tela precisa dela: o que o domínio
/// calculou, quanto já foi pago e as parcelas que caem nela.
///
/// A fatura **nunca é digitada nem guardada** (RN-330): é sempre refeita a
/// partir das compras. Apagar um lançamento muda a fatura; não existe fatura
/// "salva" que possa discordar do livro.
@immutable
final class StatementView {
  /// A fatura de [card] no ciclo [cycle], a partir de [book].
  factory of(LedgerBook book, CreditCard card, StatementCycle cycle) {
    return StatementView._(
      cycle: cycle,
      statement: CardStatement.of(
        cycle,
        entries: book.entries,
        reversals: book.reversals,
      ),
      paid: book.settlements
          .where((s) => s.cardId == card.id && s.dueMonth == cycle.dueMonth)
          .fold(Money.zero, (sum, settlement) => sum + settlement.amount),
      parceled: [
        for (final entry in book.entries)
          if (entry.installmentPlan case final plan?
              when plan.cardId == card.id &&
                  plan.installmentDueIn(cycle.dueMonth) != null)
            entry,
      ],
    );
  }

  const new _({
    required this.cycle,
    required this.statement,
    required this.paid,
    required this.parceled,
  });

  /// As duas faturas que importam hoje para [card]: a que já fechou e ainda
  /// vai vencer ou acabou de vencer, e a que está aberta.
  static List<StatementView> current(
    LedgerBook book,
    CreditCard card,
    LocalDate today,
  ) {
    final open = StatementCycle.containing(card, today);
    final closed = StatementCycle.containing(card, open.startsOn.addDays(-1));
    return [
      StatementView.of(book, card, closed),
      StatementView.of(book, card, open),
    ];
  }

  /// Quanto do limite de [card] está tomado em [today]; `null` quando o
  /// cartão não tem limite informado. A conta é do domínio (RN-305).
  static CardLimitUsage? limitOf(
    LedgerBook book,
    CreditCard card,
    LocalDate today,
  ) => CardLimitUsage.of(
    card,
    entries: book.entries,
    today: today,
    reversals: book.reversals,
    settlements: book.settlements,
    legacy: book.debts,
  );

  /// O ciclo: de quando a quando, e o vencimento.
  final StatementCycle cycle;

  /// A fatura calculada pelo domínio.
  final CardStatement statement;

  /// Quanto já foi pago desta fatura.
  final Money paid;

  /// As compras parceladas com parcela nesta fatura.
  final List<Entry> parceled;

  /// O que ainda falta pagar. Zero quando foi paga inteira — ou a mais.
  Money get openBalance => (statement.total - paid).orZeroIfNegative;

  /// Se o ciclo já fechou em [today]: a fatura não muda mais com compra nova.
  bool isClosedOn(LocalDate today) => !today.isBefore(cycle.closesOn);
}
