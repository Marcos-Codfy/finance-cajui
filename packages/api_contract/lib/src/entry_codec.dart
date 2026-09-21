import 'package:api_contract/src/create_entry_request.dart';
import 'package:api_contract/src/payment_line_dto.dart';
import 'package:domain/domain.dart';

/// A ida e a volta entre o lançamento do domínio e o pedido que viaja — e que
/// fica gravado no registro de eventos, dos dois lados.
///
/// Mora no contrato para o app e o servidor não terem, cada um, a sua versão:
/// o que o aparelho grava hoje é exatamente o que o servidor vai ler quando a
/// fila subir.
abstract final class EntryCodec {
  /// O pedido que descreve [entry].
  static CreateEntryRequest fromEntry(Entry entry) => CreateEntryRequest(
    id: entry.id,
    description: entry.description,
    amountCents: entry.amount.cents,
    occurredOn: '${entry.occurredOn}',
    categoryId: entry.categoryId,
    isExceptional: entry.isExceptional,
    paymentLines: [
      for (final line in entry.paymentLines)
        PaymentLineDto(
          paymentMethodId: line.paymentMethodId,
          kind: line.kind.name,
          amountCents: line.amount.cents,
        ),
    ],
  );

  /// Aplica as regras do domínio a [request], na categoria [category].
  ///
  /// Lança [FormatException] quando o pedido não faz sentido como pedido —
  /// data que não existe, tipo de pagamento desconhecido. Regra de negócio
  /// recusada não é exceção: volta como falha no resultado.
  static Result<Entry> toEntry(
    CreateEntryRequest request, {
    required Category category,
    required LocalDate today,
  }) {
    return Entry.create(
      id: request.id,
      description: request.description,
      amount: Money.fromCents(request.amountCents),
      occurredOn: parseDate(request.occurredOn),
      category: category,
      today: today,
      isExceptional: request.isExceptional,
      paymentLines: [
        for (final line in request.paymentLines)
          PaymentLine(
            paymentMethodId: line.paymentMethodId,
            kind: named(PaymentMethodKind.values, line.kind),
            amount: Money.fromCents(line.amountCents),
          ),
      ],
    );
  }

  /// Uma data `AAAA-MM-DD` que existe no calendário. `DateTime.parse` aceita
  /// "30 de fevereiro" e o transforma em março; aqui isso é pedido malformado.
  static LocalDate parseDate(String text) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
    if (match == null) throw FormatException('data: $text');
    final [year, month, day] = [
      for (var i = 1; i <= 3; i++) int.parse(match.group(i)!),
    ];
    final real = DateTime.utc(year, month, day);
    if (real.month != month || real.day != day) {
      throw FormatException('data inexistente: $text');
    }
    return LocalDate(year, month, day);
  }

  /// O valor de [values] chamado [name]; nome desconhecido é pedido
  /// malformado (`E-REQ-01`), não erro de quem lê.
  static T named<T extends Enum>(List<T> values, String name) =>
      values.asNameMap()[name] ?? (throw FormatException('valor: $name'));
}
