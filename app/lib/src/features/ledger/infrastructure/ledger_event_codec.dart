import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/budget/infrastructure/month_setup_codec.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/infrastructure/card_codec.dart';
import 'package:cajui/src/features/ledger/infrastructure/entry_fact_codec.dart';
import 'package:domain/domain.dart';

/// O tipo e o conteúdo com que um fato do livro é gravado.
typedef EncodedEvent = ({String type, Map<String, Object?> payload});

/// A ida e a volta entre os fatos do livro e o que vai para o registro.
///
/// O lançamento é gravado **no formato do contrato da API**, com o mesmo tipo
/// de evento que o servidor usa: o que o aparelho guarda hoje é o que a fila
/// vai enviar, sem conversão no meio.
final class LedgerEventCodec {
  /// Cria o conversor. [categoryOf] acha a categoria de um lançamento lido.
  const new({required this.categoryOf});

  /// O tipo do fato "despesa lançada" — o mesmo do servidor.
  static const entryCreated = 'entry.created';

  /// O tipo do fato "lançamento corrigido".
  static const entryCorrected = 'entry.corrected';

  /// O tipo do fato "lançamento cancelado".
  static const entryCancelled = 'entry.cancelled';

  /// O tipo do fato "compra estornada".
  static const entryReversed = 'entry.reversed';

  /// O tipo do fato "plano do mês cadastrado".
  static const planDefined = 'plan.defined';

  /// O tipo do fato "cartão cadastrado".
  static const cardDefined = 'card.defined';

  /// O tipo do fato "fatura paga".
  static const statementSettled = 'statement.settled';

  /// O tipo do fato "renda recebida".
  static const incomeReceived = 'income.received';

  /// O tipo do fato "saldo do vale corrigido".
  static const voucherAdjusted = 'voucher.adjusted';

  /// Acha a categoria pelo identificador.
  final Category Function(String id) categoryOf;

  /// Um "hoje" que nenhuma data gravada alcança. O fato já foi aceito quando
  /// aconteceu; relê-lo não pode falhar por causa do relógio.
  static final _endOfTime = LocalDate(9999, 12, 31);

  /// O que gravar para [event].
  EncodedEvent encode(LedgerEvent event) =>
      (type: _typeOf(event), payload: _payloadOf(event));

  static String _typeOf(LedgerEvent event) => switch (event) {
    EntryRecorded() => entryCreated,
    EntryCorrected() => entryCorrected,
    EntryCancelled() => entryCancelled,
    EntryReversed() => entryReversed,
    PlanDefined() => planDefined,
    CardDefined() => cardDefined,
    StatementSettled() => statementSettled,
    IncomeReceived() => incomeReceived,
    VoucherBalanceAdjusted() => voucherAdjusted,
  };

  static Map<String, Object?> _payloadOf(LedgerEvent event) => switch (event) {
    EntryRecorded(:final entry) => EntryCodec.fromEntry(entry).toJson(),
    EntryCorrected() => EntryFactCodec.encodeCorrection(event),
    EntryCancelled() => EntryFactCodec.encodeCancellation(event),
    EntryReversed(:final reversal) => EntryFactCodec.encodeReversal(reversal),
    PlanDefined(:final setup) => MonthSetupCodec.encode(setup),
    CardDefined(:final card) => CardCodec.encodeCard(card),
    StatementSettled(:final settlement) => CardCodec.encodeSettlement(
      settlement,
    ),
    IncomeReceived(:final receipt) => _encodeReceipt(receipt),
    VoucherBalanceAdjusted(:final adjustment, :final on, :final reason) => {
      'adjustmentCents': adjustment.cents,
      'on': '$on',
      'reason': reason,
    },
  };

  static Map<String, Object?> _encodeReceipt(IncomeReceipt receipt) => {
    'id': receipt.id,
    'sourceId': receipt.sourceId,
    'tender': receipt.tender.name,
    'amountCents': receipt.amount.cents,
    'receivedOn': '${receipt.receivedOn}',
  };

  static IncomeReceipt _decodeReceipt(Map<String, Object?> payload) {
    return IncomeReceipt(
      id: payload['id']! as String,
      sourceId: payload['sourceId'] as String?,
      tender: EntryCodec.named(Tender.values, payload['tender']! as String),
      amount: Money.fromCents(payload['amountCents']! as int),
      receivedOn: EntryCodec.parseDate(payload['receivedOn']! as String),
    );
  }

  /// O fato gravado com [id], [type] e [payload]; `null` para um tipo que
  /// esta versão do app não conhece — versão mais nova pode ter gravado
  /// algo a mais, e isso não impede de abrir o resto.
  ///
  /// [cardOf] e [entryOf] acham um cartão e um lançamento **já lidos** do
  /// registro: compra parcelada recalcula as parcelas a partir do cartão, e
  /// estorno se liga ao lançamento de origem.
  LedgerEvent? decode(
    String id,
    String type,
    Map<String, Object?> payload, {
    CreditCard? Function(String id)? cardOf,
    Entry? Function(String id)? entryOf,
  }) {
    Entry toEntry(Map<String, Object?> entry) => _entry(entry, cardOf);
    return switch (type) {
      entryCreated => EntryRecorded(toEntry(payload)),
      entryCorrected => EntryFactCodec.decodeCorrection(id, payload, toEntry),
      entryCancelled => EntryFactCodec.decodeCancellation(id, payload),
      entryReversed => EntryFactCodec.decodeReversal(payload, entryOf),
      planDefined => PlanDefined(
        id: id,
        setup: MonthSetupCodec.decode(payload),
      ),
      cardDefined => CardDefined(id: id, card: CardCodec.decodeCard(payload)),
      statementSettled => StatementSettled(CardCodec.decodeSettlement(payload)),
      incomeReceived => IncomeReceived(_decodeReceipt(payload)),
      voucherAdjusted => VoucherBalanceAdjusted(
        id: id,
        adjustment: Money.fromCents(payload['adjustmentCents']! as int),
        on: EntryCodec.parseDate(payload['on']! as String),
        reason: payload['reason']! as String,
      ),
      _ => null,
    };
  }

  Entry _entry(
    Map<String, Object?> payload,
    CreditCard? Function(String id)? cardOf,
  ) {
    final request = CreateEntryRequest.fromJson(payload);
    return EntryCodec.toEntry(
      request,
      category: categoryOf(request.categoryId),
      today: _endOfTime,
      cardOf: cardOf,
    ).valueOrNull!;
  }
}
