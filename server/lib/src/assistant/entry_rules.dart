import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:server/src/assistant/tool_refusal.dart';
import 'package:server/src/ledger/ledger_state.dart';

/// As regras do domínio sobre um pedido de lançamento da conversa, as
/// mesmas de qualquer lançamento (T-05). O que recusa volta ao modelo com o
/// motivo, para ele pedir o que falta.
abstract final class EntryRules {
  /// Recusa [request] se alguma regra o recusar em [state] no dia [today].
  static void check(
    CreateEntryRequest request,
    LedgerState state, {
    required LocalDate today,
  }) {
    final Result<Entry> result;
    try {
      result = state.tryCreate(request, today: today);
    } on FormatException {
      throw const ToolRefusal(
        'pedido fora do formato: confira data e parcelas',
      );
    }
    if (result.failureOrNull case final failure?) {
      throw ToolRefusal(_reason(failure));
    }
  }

  static String _reason(Failure failure) => switch (failure) {
    PurchaseDateInFuture() => 'a data da compra não pode estar no futuro',
    CategoryNotVoucherEligible() =>
      'o vale alimentação só paga categoria de alimentação',
    _ => 'recusado pela regra ${FailureMapper.map(failure).$1.code}',
  };
}
