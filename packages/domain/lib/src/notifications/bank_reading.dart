import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/notifications/bank_app.dart';
import 'package:domain/src/notifications/movement_kind.dart';
import 'package:meta/meta.dart';

/// O que uma notificação de banco disse, já lido: uma movimentação de
/// dinheiro, e nada além (RN-787).
@immutable
final class BankReading {
  /// Cria a leitura.
  const new({
    required this.app,
    required this.kind,
    required this.amount,
    required this.occurredOn,
    this.counterpart,
    this.cardDigits,
    this.installments,
  });

  /// O app que avisou.
  final BankApp app;

  /// Que movimentação foi.
  final MovementKind kind;

  /// O valor. Sempre positivo: o sentido está em [kind].
  final Money amount;

  /// O dia da movimentação.
  final LocalDate occurredOn;

  /// Com quem foi: o estabelecimento da compra, quem recebeu o Pix, quem o
  /// mandou. `null` quando o banco não diz.
  final String? counterpart;

  /// Os quatro últimos dígitos do cartão, quando a notificação os traz.
  final String? cardDigits;

  /// Em quantas vezes, quando a notificação diz que a compra foi parcelada.
  final int? installments;

  /// Se a compra foi parcelada. O plano das parcelas sai do cartão e de
  /// quem confirma (RN-311): lançar o total de uma vez contaria tudo neste
  /// mês.
  bool get isInstallment => (installments ?? 1) > 1;
}
