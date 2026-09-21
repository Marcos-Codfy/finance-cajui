import 'package:domain/domain.dart';
import 'package:persistence/persistence.dart';
import 'package:server/src/ai/chat_reply.dart';

/// O teto mensal de tokens da IA (RNF-AI-04 · T-25).
///
/// O crédito da DeepSeek é pré-pago, mas o Cajui tem o seu próprio freio: o
/// orçamento é conferido **antes** de cada chamada (RN-777), e o consumo é
/// gravado como evento — então sobrevive a um reinício e aparece no app. São
/// dois tetos independentes; se um falhar, o outro segura.
final class TokenBudget {
  /// Cria o orçamento de [monthlyLimit] tokens, somando o que já está no
  /// registro.
  new(this._store, {required this.monthlyLimit}) {
    for (final event in _store.events.where((e) => e.type == usageRecorded)) {
      _add('${event.payload['month']}', event.payload['tokens']! as int);
    }
  }

  /// O tipo do evento de consumo.
  static const usageRecorded = 'ai.usage_recorded';

  /// Quantos tokens podem ser gastos por mês.
  final int monthlyLimit;

  final EventStore _store;
  final Map<String, int> _spent = {};
  int _sequence = 0;

  void _add(String month, int tokens) =>
      _spent.update(month, (total) => total + tokens, ifAbsent: () => tokens);

  /// Quanto já foi gasto em [month].
  int spentIn(BudgetMonth month) => _spent['$month'] ?? 0;

  /// Ainda há orçamento em [month].
  bool hasRoomIn(BudgetMonth month) => spentIn(month) < monthlyLimit;

  /// Registra o custo de [reply] em [month]. O evento guarda só números: nem
  /// o pedido nem a resposta ficam gravados.
  Future<void> record(BudgetMonth month, ChatReply reply) async {
    _add('$month', reply.totalTokens);
    await _store.append(
      id: 'ai-usage-${_store.events.length + 1}-${_sequence++}',
      type: usageRecorded,
      payload: {
        'month': '$month',
        'tokens': reply.totalTokens,
        'promptTokens': reply.promptTokens,
        'completionTokens': reply.completionTokens,
      },
    );
  }
}
