import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:domain/domain.dart';

/// Por onde foi paga a movimentação que o banco avisou (RN-789).
///
/// Débito, Pix e boleto têm forma de fábrica, uma só. O cartão de crédito
/// não: a casa pode ter vários, e lançar a compra no cartão errado erra a
/// fatura dele. Por isso o cartão só é escolhido quando não há dúvida — o
/// nome do cartão traz os quatro dígitos que a notificação mostrou, ou é o
/// único cadastrado com o nome do banco que avisou. Fora disso, `null`, e
/// quem escolhe é a pessoa, com um toque.
abstract final class NoticePaymentMethod {
  /// A forma de [reading] em [book]; `null` quando não dá para saber.
  static PaymentMethod? of(BankReading reading, LedgerBook book) {
    final kind = reading.kind.paymentKind;
    if (kind == null) return null;
    if (kind.isCreditCard) return _card(reading, book);
    return book.methods.where((method) => method.kind == kind).firstOrNull;
  }

  static PaymentMethod? _card(BankReading reading, LedgerBook book) {
    final cards = [
      for (final method in book.methods)
        if (method.kind.isCreditCard) method,
    ];
    final digits = reading.cardDigits;
    if (digits != null) {
      final byDigits = cards.where((card) => card.name.contains(digits));
      if (byDigits.length == 1) return byDigits.single;
    }
    final byBank = cards.where((card) => reading.app.namesCard(card.name));
    return byBank.length == 1 ? byBank.single : null;
  }
}
