import 'package:api_contract/src/json_reader.dart';
import 'package:api_contract/src/payment_line_dto.dart';
import 'package:meta/meta.dart';

/// O comando de criar um lançamento: `POST /v1/entries`.
///
/// O [id] é criado no aparelho e é a **chave de idempotência**: o mesmo
/// comando enviado duas vezes — porque a resposta se perdeu, porque a fila
/// offline tentou de novo — vira um lançamento só (ADR-012).
@immutable
final class CreateEntryRequest {
  /// Cria o comando.
  const new({
    required this.id,
    required this.description,
    required this.amountCents,
    required this.occurredOn,
    required this.categoryId,
    required this.paymentLines,
    this.isExceptional = false,
    this.installments,
  });

  /// Lê o comando, recusando o que estiver fora do formato (`E-REQ-01`).
  factory fromJson(Object? json) {
    final reader = JsonReader(
      json,
      allowed: const {
        'id',
        'description',
        'amountCents',
        'occurredOn',
        'categoryId',
        'paymentLines',
        'isExceptional',
        'installments',
      },
    );
    return CreateEntryRequest(
      id: reader.string('id', maxLength: 64),
      description: reader.string('description'),
      amountCents: reader.integer('amountCents'),
      occurredOn: reader.string('occurredOn', maxLength: 10),
      categoryId: reader.string('categoryId', maxLength: 64),
      paymentLines: reader
          .list('paymentLines')
          .map(PaymentLineDto.fromJson)
          .toList(),
      isExceptional: reader.boolean('isExceptional', orElse: false),
      installments: reader.optionalInteger('installments'),
    );
  }

  /// O identificador do lançamento, criado no aparelho.
  final String id;

  /// O que foi comprado.
  final String description;

  /// O valor, em centavos.
  final int amountCents;

  /// A data da compra, no formato `AAAA-MM-DD`.
  final String occurredOn;

  /// A categoria.
  final String categoryId;

  /// Por onde foi pago.
  final List<PaymentLineDto> paymentLines;

  /// Gasto fora do padrão.
  final bool isExceptional;

  /// Em quantas parcelas a compra foi feita no cartão de crédito; `null`
  /// quando é à vista. As parcelas são recalculadas a partir do cartão e da
  /// data: o pedido não carrega valor de parcela que alguém pudesse forjar.
  final int? installments;

  /// O comando em JSON.
  Map<String, Object?> toJson() => {
    'id': id,
    'description': description,
    'amountCents': amountCents,
    'occurredOn': occurredOn,
    'categoryId': categoryId,
    'paymentLines': [for (final line in paymentLines) line.toJson()],
    'isExceptional': isExceptional,
    // Só viaja quando a compra é parcelada: pedido à vista continua igual
    // ao de antes, e quem grava hoje lê amanhã.
    'installments': ?installments,
  };
}
