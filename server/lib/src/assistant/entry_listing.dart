import 'package:domain/domain.dart';
import 'package:server/src/assistant/payment_choice.dart';
import 'package:server/src/ledger/ledger_state.dart';

/// Os lançamentos de um mês, como o modelo os lê: um por linha, do mais
/// recente para o mais antigo, com os totais por moeda — nunca somados
/// entre si (RN-111).
///
/// A lista é da casa do dono, e vai inteira até o teto: é ele quem pergunta
/// "o que gastei em farmácia", e a resposta precisa dos nomes. Acima do
/// teto vão os mais recentes, e o total diz quantos ficaram de fora.
abstract final class EntryListing {
  /// Quantas linhas, no máximo, vão ao modelo.
  static const maxLines = 60;

  /// A listagem de [month].
  static Map<String, Object?> of(
    LedgerState state, {
    required BudgetMonth month,
  }) {
    final entries =
        state.entries
            .where((entry) => entry.occurredOn.budgetMonth == month)
            .toList()
          ..sort((a, b) => b.occurredOn.compareTo(a.occurredOn));
    final spent = entries.fold(
      TenderAmounts.zero,
      (sum, entry) => sum + entry.spentIn(month),
    );
    return {
      'mes': '$month',
      'total_lancamentos': entries.length,
      'listados': entries.length > maxLines ? maxLines : entries.length,
      'gasto_centavos_dinheiro': spent.cash.cents,
      'gasto_centavos_vale': spent.mealVoucher.cents,
      'lancamentos': [
        for (final entry in entries.take(maxLines)) _line(state, entry),
      ],
    };
  }

  static Map<String, Object?> _line(LedgerState state, Entry entry) => {
    'id': entry.id,
    'data': '${entry.occurredOn}',
    'descricao': entry.description,
    'valor_centavos': entry.amount.cents,
    'categoria': state.categories[entry.categoryId]?.name ?? entry.categoryId,
    'forma': [
      for (final line in entry.paymentLines)
        PaymentChoice.labelOf(line.paymentMethodId, state.cards),
    ].join(' + '),
    if (entry.installmentPlan case final plan?)
      'parcelas': plan.installments.length,
  };
}
