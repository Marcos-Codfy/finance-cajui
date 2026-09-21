import 'package:api_contract/src/json_reader.dart';
import 'package:meta/meta.dart';

/// Uma linha de pagamento, como atravessa a rede.
@immutable
final class PaymentLineDto {
  /// Cria a linha.
  const new({
    required this.paymentMethodId,
    required this.kind,
    required this.amountCents,
  });

  /// Lê a linha, recusando o que estiver fora do formato.
  factory fromJson(Object? json) {
    final reader = JsonReader(
      json,
      allowed: const {'paymentMethodId', 'kind', 'amountCents'},
    );
    return PaymentLineDto(
      paymentMethodId: reader.string('paymentMethodId', maxLength: 64),
      kind: reader.string('kind', maxLength: 32),
      amountCents: reader.integer('amountCents'),
    );
  }

  /// A forma de pagamento usada.
  final String paymentMethodId;

  /// O tipo da forma de pagamento, pelo nome: `pix`, `creditCard`.
  final String kind;

  /// O valor, em centavos.
  final int amountCents;

  /// A linha em JSON.
  Map<String, Object?> toJson() => {
    'paymentMethodId': paymentMethodId,
    'kind': kind,
    'amountCents': amountCents,
  };
}
