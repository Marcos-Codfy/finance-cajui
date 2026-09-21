import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/budget/infrastructure/month_setup_codec.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/infrastructure/card_codec.dart';
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

  /// O tipo do fato "plano do mês cadastrado".
  static const planDefined = 'plan.defined';

  /// O tipo do fato "cartão cadastrado".
  static const cardDefined = 'card.defined';

  /// O tipo do fato "fatura paga".
  static const statementSettled = 'statement.settled';

  /// O tipo do fato "saldo do vale corrigido".
  static const voucherAdjusted = 'voucher.adjusted';

  /// Acha a categoria pelo identificador.
  final Category Function(String id) categoryOf;

  /// Um "hoje" que nenhuma data gravada alcança. O fato já foi aceito quando
  /// aconteceu; relê-lo não pode falhar por causa do relógio.
  static final _endOfTime = LocalDate(9999, 12, 31);

  /// O que gravar para [event].
  EncodedEvent encode(LedgerEvent event) => switch (event) {
    EntryRecorded(:final entry) => (
      type: entryCreated,
      payload: EntryCodec.fromEntry(entry).toJson(),
    ),
    PlanDefined(:final setup) => (
      type: planDefined,
      payload: MonthSetupCodec.encode(setup),
    ),
    CardDefined(:final card) => (
      type: cardDefined,
      payload: CardCodec.encodeCard(card),
    ),
    StatementSettled(:final settlement) => (
      type: statementSettled,
      payload: CardCodec.encodeSettlement(settlement),
    ),
    VoucherBalanceAdjusted(:final adjustment, :final on, :final reason) => (
      type: voucherAdjusted,
      payload: {
        'adjustmentCents': adjustment.cents,
        'on': '$on',
        'reason': reason,
      },
    ),
  };

  /// O fato gravado com [id], [type] e [payload]; `null` para um tipo que
  /// esta versão do app não conhece — versão mais nova pode ter gravado
  /// algo a mais, e isso não impede de abrir o resto.
  ///
  /// [cardOf] acha um cartão **já lido** do registro: compra parcelada
  /// recalcula as parcelas a partir dele.
  LedgerEvent? decode(
    String id,
    String type,
    Map<String, Object?> payload, {
    CreditCard? Function(String id)? cardOf,
  }) {
    return switch (type) {
      entryCreated => _entry(payload, cardOf),
      planDefined => PlanDefined(
        id: id,
        setup: MonthSetupCodec.decode(payload),
      ),
      cardDefined => CardDefined(id: id, card: CardCodec.decodeCard(payload)),
      statementSettled => StatementSettled(CardCodec.decodeSettlement(payload)),
      voucherAdjusted => VoucherBalanceAdjusted(
        id: id,
        adjustment: Money.fromCents(payload['adjustmentCents']! as int),
        on: EntryCodec.parseDate(payload['on']! as String),
        reason: payload['reason']! as String,
      ),
      _ => null,
    };
  }

  LedgerEvent _entry(
    Map<String, Object?> payload,
    CreditCard? Function(String id)? cardOf,
  ) {
    final request = CreateEntryRequest.fromJson(payload);
    final entry = EntryCodec.toEntry(
      request,
      category: categoryOf(request.categoryId),
      today: _endOfTime,
      cardOf: cardOf,
    );
    return EntryRecorded(entry.valueOrNull!);
  }
}
