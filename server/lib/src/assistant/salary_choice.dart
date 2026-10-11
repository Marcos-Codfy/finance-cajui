import 'package:domain/domain.dart';
import 'package:server/src/assistant/server_finances.dart';
import 'package:server/src/assistant/tool_refusal.dart';
import 'package:server/src/ledger/ledger_state.dart';

/// De quem é o salário que a Juju vai registrar (RN-758 e RN-1006).
///
/// O recebido toma o lugar do esperado daquele salário no mês. Por isso
/// errar de pessoa troca a renda inteira: o salário de outra pessoa, ou um
/// já recebido, somaria em dobro.
abstract final class SalaryChoice {
  /// O salário de [amount] recebido em [on]; `null` é entrada avulsa.
  ///
  /// Vale, nesta ordem: o salário que a IA nomeou ([requested]); o que se
  /// parece com o valor e o dia; o único ainda não recebido no mês. Com dois
  /// ou mais ainda abertos e nenhum parecido, a ferramenta pergunta de quem
  /// é, em vez de adivinhar. Sem salário nenhum no plano, é avulsa: não há
  /// esperado para trocar.
  static IncomeSource? of(
    LedgerState state, {
    required Money amount,
    required LocalDate on,
    String? requested,
  }) {
    final finances = ServerFinances.of(state);
    final salaries = finances.planFor(on.budgetMonth).salaries;
    if (requested != null) return _named(salaries, requested);
    final like = finances.salaryLike(amount, on);
    if (like != null) return like;
    final open = [
      for (final salary in salaries)
        if (!_received(state, salary, on.budgetMonth)) salary,
    ];
    if (open.length <= 1) return open.firstOrNull;
    final names = open.map((salary) => '${salary.id}: ${salary.name}');
    throw ToolRefusal(
      'a casa tem mais de um salário ainda não recebido neste mês '
      '(${names.join(', ')}); diga de quem é com salario_id, ou pergunte '
      'à pessoa',
    );
  }

  static IncomeSource _named(List<IncomeSource> salaries, String id) =>
      salaries.where((salary) => salary.id == id).firstOrNull ??
      (throw ToolRefusal(
        'salário desconhecido: "$id"; use um destes ids: '
        '${salaries.map((salary) => salary.id).join(', ')}',
      ));

  static bool _received(
    LedgerState state,
    IncomeSource salary,
    BudgetMonth month,
  ) => state.receipts.values.any(
    (receipt) =>
        receipt.sourceId == salary.id && month.contains(receipt.receivedOn),
  );
}
