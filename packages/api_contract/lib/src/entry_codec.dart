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
    installments: entry.installmentPlan?.count,
    // O valor da parcela só viaja quando há juros: sem eles, dividir o
    // principal dá o mesmo resultado dos dois lados, e o campo seria peso
    // morto em todo lançamento parcelado.
    installmentAmountCents: _interestBearing(entry.installmentPlan),
    origin: entry.origin == EntryOrigin.manual ? null : entry.origin.name,
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
  ///
  /// [cardOf] acha o cartão de uma compra parcelada. O parcelamento é
  /// **recalculado** a partir do cartão e da data da compra (RN-311): o
  /// pedido traz só quantas parcelas, nunca o valor de cada uma.
  ///
  /// [fromOwnJournal] diz que o pedido veio do registro **deste** aparelho,
  /// e não da rede. Só então o valor de parcela gravado é aceito, para um
  /// plano com juros não voltar com os juros zerados (BL-054).
  static Result<Entry> toEntry(
    CreateEntryRequest request, {
    required Category category,
    required LocalDate today,
    CreditCard? Function(String id)? cardOf,
    bool fromOwnJournal = false,
  }) {
    final on = parseDate(request.occurredOn);
    final lines = _lines(request);
    return Entry.create(
      id: request.id,
      description: request.description,
      amount: Money.fromCents(request.amountCents),
      occurredOn: on,
      category: category,
      today: today,
      isExceptional: request.isExceptional,
      origin: named(EntryOrigin.values, request.origin ?? 'manual'),
      paymentLines: lines,
      installmentPlan: _plan(request, lines, on, cardOf, fromOwnJournal),
    );
  }

  /// As linhas de pagamento do pedido, como o domínio as quer.
  static List<PaymentLine> _lines(CreateEntryRequest request) => [
    for (final line in request.paymentLines)
      PaymentLine(
        paymentMethodId: line.paymentMethodId,
        kind: named(PaymentMethodKind.values, line.kind),
        amount: Money.fromCents(line.amountCents),
      ),
  ];

  /// O valor da parcela de um plano **com juros**; `null` quando as parcelas
  /// são o principal dividido em partes iguais.
  static int? _interestBearing(InstallmentPlan? plan) =>
      plan == null || plan.interestTotal.isZero
      ? null
      : plan.installments.first.amount.cents;

  /// O parcelamento da compra; `null` quando ela é à vista. Parcelar exige
  /// uma linha no cartão de crédito e um cartão conhecido — sem isso o
  /// pedido é malformado.
  static InstallmentPlan? _plan(
    CreateEntryRequest request,
    List<PaymentLine> lines,
    LocalDate purchasedOn,
    CreditCard? Function(String id)? cardOf,
    bool fromOwnJournal,
  ) {
    final count = request.installments;
    final cents = fromOwnJournal ? request.installmentAmountCents : null;
    if (count == null || count < 2) return null;
    if (count > maxInstallments) throw const FormatException('parcelas');
    final onCard = lines.where((line) => line.kind.isCreditCard).firstOrNull;
    final card = onCard == null ? null : cardOf?.call(onCard.paymentMethodId);
    if (onCard == null || card == null) {
      throw const FormatException('parcelamento sem cartão conhecido');
    }
    return InstallmentPlan.forPurchase(
      card: card,
      purchasedOn: purchasedOn,
      principal: onCard.amount,
      count: count,
      installmentAmount: cents == null ? null : Money.fromCents(cents),
    );
  }

  /// O maior número de parcelas aceito.
  static const maxInstallments = 24;

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
