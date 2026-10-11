import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Os casos de uso do plano da planilha (ADR-023): salvar "Minhas contas"
/// com o que entra e o dízimo, e decidir a ordem de quitação das dívidas.
///
/// Os dois viram fatos que atravessam os aparelhos como estão, e o mais novo
/// pelo carimbo vale — por isso o carimbo é a hora de agora, e não a de
/// chegada ao servidor.
class PlanService {
  /// Cria o caso de uso sobre os providers de [ref].
  const new(this.ref);

  /// De onde saem o livro e o relógio.
  final Ref ref;

  /// Salva [plan] como o plano em vigor.
  Future<void> define(BudgetPlan plan) async {
    final book = await ref.read(ledgerProvider.future);
    final known = BookFinances.of(book).plan.definedAt;
    await ref
        .read(ledgerProvider.notifier)
        .append(BudgetDefined(plan.savedAt(_after(known))));
  }

  /// Decide que as dívidas se quitam na ordem [ids].
  Future<void> orderDebts(List<String> ids) async {
    final book = await ref.read(ledgerProvider.future);
    final at = _after(book.budget.orderedAt);
    await ref
        .read(ledgerProvider.notifier)
        .append(DebtOrdered(ids: ids, definedAt: at));
  }

  /// O carimbo de agora, ou logo depois de [known] se o relógio daqui
  /// estiver atrás (ADR-024): quem muda depois de ver a mudança do outro
  /// aparelho vence, mesmo com o relógio atrasado — senão a mudança sumia
  /// da tela na hora.
  DateTime _after(DateTime? known) {
    final now = ref.read(clockProvider).now();
    if (known == null || now.isAfter(known)) return now;
    return known.add(const Duration(milliseconds: 1));
  }
}

/// O caso de uso do plano.
final planServiceProvider = Provider<PlanService>(PlanService.new);
