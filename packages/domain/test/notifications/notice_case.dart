import 'package:domain/domain.dart';
import 'package:test/test.dart';

/// O dia em que as notificações dos testes chegam.
final noticeDay = LocalDate(2026, 10, 10);

/// Uma notificação fictícia de [app], com [title] e [text]: nenhum valor,
/// nome ou cartão aqui é de gente de verdade.
BankReading? readNotice(BankApp app, String title, String text) =>
    BankNotificationParser.read(
      BankNotification(
        packageName: app.packageNames.first,
        title: title,
        text: text,
        postedOn: noticeDay,
      ),
    );

/// Confere que [reading] é a movimentação esperada.
void expectReading(
  BankReading? reading, {
  required MovementKind kind,
  required int cents,
  String? counterpart,
  String? digits,
}) {
  expect(reading, isNotNull, reason: 'devia ser lida como movimentação');
  expect(reading!.kind, kind);
  expect(reading.amount, Money.fromCents(cents));
  expect(reading.occurredOn, noticeDay);
  expect(reading.counterpart, counterpart);
  if (digits != null) expect(reading.cardDigits, digits);
}
