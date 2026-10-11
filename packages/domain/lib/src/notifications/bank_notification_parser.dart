import 'package:domain/src/notifications/bank_app.dart';
import 'package:domain/src/notifications/bank_notification.dart';
import 'package:domain/src/notifications/bank_reading.dart';
import 'package:domain/src/notifications/counterpart_reader.dart';
import 'package:domain/src/notifications/movement_reader.dart';
import 'package:domain/src/notifications/notice_text.dart';

/// Lê a notificação de um app de banco (RN-786 e RN-787).
///
/// Devolve a movimentação de dinheiro que ela avisa, ou `null` para todo o
/// resto: propaganda, saldo, fatura fechada, código de acesso, alerta de
/// limite, pagamento de fatura, compra recusada. Na dúvida, `null`: uma
/// notificação ignorada a pessoa lança à mão; uma lida errado vira um gasto
/// que ela não fez.
abstract final class BankNotificationParser {
  /// A leitura de [notice]; `null` quando não é movimentação de dinheiro, ou
  /// quando não veio de um banco da lista.
  static BankReading? read(BankNotification notice) {
    final app = BankApp.ofPackage(notice.packageName);
    if (app == null) return null;
    final whole = '${notice.title}\n${notice.text}';
    final kind = MovementReader.kindIn(NoticeText.fold(whole), app);
    if (kind == null) return null;
    final amount = NoticeText.amountIn(whole);
    if (amount == null || !amount.isPositive) return null;
    return BankReading(
      app: app,
      kind: kind,
      amount: amount,
      occurredOn: notice.postedOn,
      counterpart: CounterpartReader.nameIn(notice, kind),
      cardDigits: NoticeText.cardDigitsIn(whole),
      installments: NoticeText.installmentsIn(whole),
    );
  }
}
