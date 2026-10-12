import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:domain/domain.dart';

/// O que uma linha de extrato vira ao ser lançada: por onde saiu e, se é
/// dinheiro que entrou, de que salário (RN-111, RN-758).
///
/// A tela de lista do extrato (RN-707) saiu em 12/10/2026: todo extrato vai
/// para a conversa com a Juju (RN-1100). Ficaram estas duas regras, que a
/// gravação em lote da conversa usa.
abstract final class StatementImport {
  /// Por onde a despesa da linha saiu. O extrato é de uma conta: sem a forma
  /// escrita, é débito ou Pix — **nunca** a última forma usada, que podia ser
  /// o vale (RN-111) ou um cartão. Vale e cartão só quando a linha diz.
  static PaymentMethod? methodFor(StatementLine line, LedgerBook book) {
    PaymentMethod? of(PaymentMethodKind kind) =>
        book.methods.where((method) => method.kind == kind).firstOrNull;
    return switch (line.paymentKind) {
      final PaymentMethodKind kind => of(kind),
      null => of(PaymentMethodKind.debit) ?? of(PaymentMethodKind.pix),
    };
  }

  /// O salário que a entrada da linha parece ser (RN-758); nulo quando é
  /// entrada avulsa.
  static IncomeSource? salaryOf(StatementLine line, LedgerBook book) =>
      (line.paymentKind?.tender ?? Tender.cash) == Tender.cash
      ? BookFinances.of(book).salaryLike(line.amount, line.occurredOn)
      : null;
}
