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
    this.installmentAmountCents,
    this.origin,
    this.revisedAt,
  });

  /// Lê o comando, recusando o que estiver fora do formato (`E-REQ-01`).
  factory fromJson(Object? json) =>
      CreateEntryRequest._read(JsonReader(json, allowed: _fields));

  factory _read(JsonReader reader) => CreateEntryRequest(
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
    installmentAmountCents: reader.optionalInteger('installmentAmountCents'),
    origin: reader.optionalString('origin', maxLength: 16),
    revisedAt: reader.optionalInstant('revisedAt'),
  );

  /// [json] só com os campos que este contrato conhece. É como o **cliente**
  /// lê o que vem do servidor: um servidor mais novo, com um campo a mais,
  /// não pode esvaziar a comparação e fazer o app reenviar o livro inteiro
  /// a cada subida. O servidor continua lendo estrito.
  static Map<String, Object?> known(Map<String, Object?> json) => {
    for (final MapEntry(:key, :value) in json.entries)
      if (_fields.contains(key)) key: value,
  };

  /// Os campos que o pedido pode ter, e só eles: campo a mais é
  /// `E-REQ-01`, que é o que impede escrever em atributo não previsto.
  static const Set<String> _fields = {
    'id',
    'description',
    'amountCents',
    'occurredOn',
    'categoryId',
    'paymentLines',
    'isExceptional',
    'installments',
    'installmentAmountCents',
    'origin',
    'revisedAt',
  };

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
  /// quando é à vista.
  final int? installments;

  /// O valor de cada parcela, quando a compra tem **juros** e as parcelas
  /// não são o valor dividido em partes iguais (RN-314).
  ///
  /// O servidor **ignora** este campo, de propósito: parcela vinda do
  /// cliente é número que alguém poderia forjar, e lá o plano é sempre
  /// recalculado a partir do cartão (T-05, RN-311). Ele existe para o
  /// aparelho reler o **próprio** registro sem perder os juros — antes do
  /// BL-054, um plano com juros voltava com `interestTotal` zerado.
  final int? installmentAmountCents;

  /// Como o lançamento nasceu: `manual` ou `share`. Ausente vale `manual`.
  ///
  /// Sem ele, todo lançamento relido virava manual e o "veio de comprovante"
  /// sumia ao reabrir o app (BL-054).
  final String? origin;

  /// Quando o lançamento foi corrigido pela última vez, em UTC; ausente
  /// quando nunca foi. Entre dois celulares, é o que decide qual correção
  /// vale: a mais nova, e não a que chegou por último (BL-062).
  final DateTime? revisedAt;

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
    'installmentAmountCents': ?installmentAmountCents,
    'origin': ?origin,
    'revisedAt': ?revisedAt?.toIso8601String(),
  };
}
