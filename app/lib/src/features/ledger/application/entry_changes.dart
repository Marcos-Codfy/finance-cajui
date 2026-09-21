import 'package:domain/domain.dart';

/// O que mudou entre duas versões de um lançamento, dito em palavras.
///
/// É o "motivo" que a correção leva para o registro (RN-208): quem abrir o
/// histórico depois sabe **em quê** o lançamento foi mexido, sem precisar
/// comparar os dois fatos campo a campo.
abstract final class EntryChanges {
  /// Os nomes dos campos que mudaram de [before] para [after], na ordem da
  /// tela. Vazio quando as duas versões dizem a mesma coisa.
  static List<String> between(Entry before, Entry after) => [
    if (before.amount != after.amount) 'valor',
    if (before.description != after.description) 'descrição',
    if (before.categoryId != after.categoryId) 'categoria',
    if (!_samePayment(before, after)) 'forma de pagamento',
    if (before.occurredOn != after.occurredOn) 'data',
  ];

  static bool _samePayment(Entry before, Entry after) =>
      _payment(before) == _payment(after);

  /// As linhas de pagamento e o número de parcelas, num texto comparável.
  static String _payment(Entry entry) {
    final lines = entry.paymentLines
        .map((line) => '${line.paymentMethodId}:${line.amount.cents}')
        .join('+');
    return '$lines/${entry.installmentPlan?.installments.length ?? 1}';
  }
}
