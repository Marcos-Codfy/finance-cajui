import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fechar o mês: congelar o retrato de um mês encerrado (RN-440).
///
/// A falta de um mês fechado **não vira dívida** e não é descontada do mês
/// seguinte por conta própria (RN-443): o fechamento informa, e o que fazer
/// com o número é decisão de quem usa.
class MonthClosing {
  /// Cria o caso de uso sobre os providers de [ref].
  const new(this.ref);

  /// De onde saem o livro e o relógio.
  final Ref ref;

  /// Fecha [month] com o resultado realizado do próprio livro (RN-623).
  ///
  /// Mês que ainda não terminou é recusado pelo domínio (`E-BUDG-02`), e
  /// nada é gravado. Mês já fechado não fecha de novo: quem cuida disso é a
  /// revisão automática do lançamento tardio (RN-441).
  Future<Result<MonthClose>> close(BudgetMonth month) async {
    final book = await ref.read(ledgerProvider.future);
    if (book.closeOf(month) != null) return Ok(book.closeOf(month)!);
    final result = MonthClose.close(
      month: month,
      cashResult: book.cashResultIn(month),
      today: ref.read(clockProvider).today(),
    );
    if (result.valueOrNull case final close?) {
      await ref.read(ledgerProvider.notifier).append(MonthClosed(close));
    }
    return result;
  }
}

/// O caso de uso de fechar o mês.
final monthClosingProvider = Provider<MonthClosing>(MonthClosing.new);

/// O mês passado, que é o que se fecha hoje.
final closableMonthProvider = Provider<BudgetMonth>(
  (ref) => ref.watch(clockProvider).today().budgetMonth.previous,
);
