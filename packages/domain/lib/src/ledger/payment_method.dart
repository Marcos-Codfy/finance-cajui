import 'package:domain/src/ledger/payment_line.dart';
import 'package:domain/src/ledger/payment_method_kind.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/money/tender.dart';
import 'package:meta/meta.dart';

/// Por onde uma compra foi paga: Pix, débito, dinheiro vivo, vale.
///
/// É o "como", separado do "o quê" — o conceito central do produto. Nenhuma
/// forma de pagamento é despesa; ela só diz de que bolso, e em que moeda, o
/// valor saiu (RN-205).
@immutable
final class PaymentMethod {
  /// Cria a forma de pagamento [name], do tipo [kind].
  const new({required this.id, required this.name, required this.kind});

  /// O identificador estável.
  final String id;

  /// O nome que a pessoa deu: "Pix", "Vale", "Nubank".
  final String name;

  /// O tipo, que decide a moeda.
  final PaymentMethodKind kind;

  /// A moeda em que esta forma paga.
  Tender get tender => kind.tender;

  /// Uma linha de pagamento de [amount] por esta forma.
  PaymentLine line(Money amount) =>
      PaymentLine(paymentMethodId: id, kind: kind, amount: amount);

  @override
  bool operator ==(Object other) => other is PaymentMethod && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
