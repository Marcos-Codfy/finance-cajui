import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Os casos de uso do que **entra**: a renda recebida e o acerto do saldo do
/// vale.
///
/// Recebimento não é lançamento (RN-132): não tem categoria, não entra em
/// bloco de despesa e nunca se compensa com um gasto. Por isso mora aqui, e
/// não no controlador do livro — que fica com o que sai.
class IncomeService {
  /// Cria o caso de uso sobre os providers de [ref].
  const new(this.ref);

  /// De onde saem o livro, o relógio e o gerador de identificador.
  final Ref ref;

  LedgerController get _ledger => ref.read(ledgerProvider.notifier);

  /// Registra uma renda recebida. Em dinheiro, [salaryId] diz de quem é o
  /// salário — que passa a valer no lugar do esperado no mês (RN-131) —, e
  /// sem ele é entrada avulsa, contada só no mês em que entrou (RN-133). No
  /// vale, é o crédito do mês (RN-1006). Valor zero não gera fato.
  Future<void> receiveIncome({
    required Tender tender,
    required Money amount,
    required LocalDate receivedOn,
    String? salaryId,
    String? id,
  }) async {
    if (!amount.isPositive) return;
    // Recebimento que nasce de um comprovante usa a chave dele: confirmar de
    // novo, depois de adiar e reabrir, não registra a renda duas vezes.
    if (id != null) {
      final book = await ref.read(ledgerProvider.future);
      if (book.receipts.any((receipt) => receipt.id == id)) return;
    }
    await _ledger.append(
      IncomeReceived(
        IncomeReceipt(
          id: id ?? ref.read(newIdProvider)(),
          sourceId: tender == Tender.cash ? salaryId : null,
          tender: tender,
          amount: amount,
          receivedOn: receivedOn,
        ),
      ),
    );
  }

  /// Corrige o saldo do vale para [actual], o que a operadora mostra
  /// (RN-123). Saldo que já bate não gera fato nenhum.
  Future<void> setVoucherBalance(Money actual, {required String reason}) async {
    final book = await ref.read(ledgerProvider.future);
    final adjustment = book.voucher.adjustmentTo(actual);
    if (adjustment.isZero) return;
    await _ledger.append(
      VoucherBalanceAdjusted(
        VoucherAdjustment(
          id: ref.read(newIdProvider)(),
          amount: adjustment,
          on: ref.read(clockProvider).today(),
          reason: reason,
        ),
      ),
    );
  }
}

/// Os casos de uso do que entra.
final incomeServiceProvider = Provider<IncomeService>(IncomeService.new);
