import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Os casos de uso das dívidas: cadastrar, pagar a parcela do mês e guardar
/// o valor para quitar que o credor informou.
///
/// A dívida é fato e distância a percorrer — "faltam 7 parcelas de R$ 212,00"
/// —, nunca bronca (RN-542). Nenhuma conta é feita aqui: saldo, previsão de
/// quitação e simulação são do domínio.
class DebtsService {
  /// Cria o caso de uso sobre os providers de [ref].
  const new(this.ref);

  /// De onde saem o livro, o relógio e o gerador de identificador.
  final Ref ref;

  /// A categoria em que o pagamento de parcela é lançado.
  static const installmentCategoryId = 'debt-installment';

  /// Cadastra ou altera uma dívida (RN-501). Parcela não positiva ou pagas
  /// além do total voltam como falha do domínio, e nada é gravado.
  Future<Result<Debt>> define({
    required String creditor,
    required DebtKind kind,
    required Money installmentAmount,
    required int totalInstallments,
    required int paidInstallments,
    required int dueDay,
    required BudgetMonth firstMonth,
    String? id,
    String? note,
  }) async {
    final result = Debt.create(
      id: id ?? 'debt-${ref.read(newIdProvider)()}',
      creditor: creditor.trim(),
      kind: kind,
      installmentAmount: installmentAmount,
      totalInstallments: totalInstallments,
      paidInstallments: paidInstallments,
      dueDay: dueDay,
      firstMonth: firstMonth,
      note: note,
    );
    if (result.valueOrNull case final debt?) await _save(debt);
    return result;
  }

  /// Cadastra a dívida que se mede pelo saldo — conta atrasada, rotativo
  /// (RN-1002). A parcela por mês pode ser zero; o saldo cai sozinho a cada
  /// vencimento (RN-1030).
  Future<Result<Debt>> defineByBalance({
    required String creditor,
    required DebtKind kind,
    required Money balance,
    required Money monthlyPayment,
    required int dueDay,
    String? note,
  }) async {
    final result = Debt.withBalance(
      id: 'debt-${ref.read(newIdProvider)()}',
      creditor: creditor.trim(),
      kind: kind,
      balance: balance,
      monthlyPayment: monthlyPayment,
      dueDay: dueDay,
      informedOn: ref.read(clockProvider).today(),
      note: note,
    );
    if (result.valueOrNull case final debt?) await _save(debt);
    return result;
  }

  /// Atualiza o saldo de [debt] para [balance], informado hoje: depois de
  /// negociar, ou para dizer que quitou (saldo zero). É uma versão nova, e
  /// não uma reescrita: os meses passados continuam com a que valia neles
  /// (RN-1040). Só a dívida de saldo informado passa por aqui — a parcelada
  /// segue o calendário (RN-1030).
  Future<void> updateBalance(Debt debt, Money balance) async {
    final updated = Debt.withBalance(
      id: debt.id,
      creditor: debt.creditor,
      kind: debt.kind,
      balance: balance,
      monthlyPayment: debt.installmentAmount,
      dueDay: debt.dueDay,
      informedOn: ref.read(clockProvider).today(),
      note: debt.note,
    ).valueOrNull;
    if (updated == null) return;
    await _save(updated.keepingFrom(debt));
  }

  /// Guarda o valor para quitar hoje que o credor informou (RN-511). O app
  /// não calcula tabela de juros por conta própria: mostra o que foi dito,
  /// com a data, e avisa quando envelhece (RN-512).
  Future<void> setPayoffQuote(Debt debt, Money amount) async {
    final quote = PayoffQuote(
      amount: amount,
      quotedOn: ref.read(clockProvider).today(),
    );
    await _save(debt.withPayoffQuote(quote));
  }

  /// Grava a versão [debt], carimbada (ADR-024): agora, ou logo depois da
  /// versão que o aparelho já tem, se o relógio daqui estiver atrás. Quem
  /// muda a dívida depois de ver a mudança do outro vence, mesmo com o
  /// relógio atrasado.
  Future<void> _save(Debt debt) async {
    final now = ref.read(clockProvider).now();
    final book = await ref.read(ledgerProvider.future);
    final known = book.debtOf(debt.id)?.definedAt;
    final at = known != null && !now.isAfter(known)
        ? known.add(const Duration(milliseconds: 1))
        : now;
    await _append(
      DebtDefined(
        id: 'debt-fact-${ref.read(newIdProvider)()}',
        debt: debt.stamped(at),
      ),
    );
  }

  /// Paga a parcela do mês de [debt] (RN-520).
  ///
  /// O pagamento **é um lançamento** do bloco de dívidas, com as mesmas
  /// regras de qualquer outro; este caso de uso só o liga à dívida, para ela
  /// contar mais uma parcela paga. Parcelamento no cartão não passa por aqui:
  /// a parcela já é cobrada na fatura, e lançar de novo contaria duas vezes
  /// (RN-521).
  Future<Result<Entry>> payInstallment(
    Debt debt, {
    required PaymentMethod method,
    required LocalDate on,
  }) async {
    assert(
      debt.kind != DebtKind.cardInstallment,
      'Parcela no cartão é cobrada na fatura, e não se lança de novo.',
    );
    final book = await ref.read(ledgerProvider.future);
    final result = await ref
        .read(ledgerProvider.notifier)
        .record(_draftFor(debt, book, method: method, on: on));
    if (result.valueOrNull case final entry?) {
      await _append(DebtInstallmentPaid(debtId: debt.id, entryId: entry.id));
    }
    return result;
  }

  /// O rascunho do lançamento da parcela: "Empréstimo Banco X · parcela 6
  /// de 12" diz, na própria lista de lançamentos, onde a pessoa está.
  EntryDraft _draftFor(
    Debt debt,
    LedgerBook book, {
    required PaymentMethod method,
    required LocalDate on,
  }) => EntryDraft(
    amountCents: debt.installmentAmount.cents,
    description:
        '${debt.creditor} · parcela ${debt.paidInstallments + 1} '
        'de ${debt.totalInstallments}',
    category: book.categoryOf(installmentCategoryId),
    method: method,
    occurredOn: on,
  );

  Future<void> _append(LedgerEvent event) =>
      ref.read(ledgerProvider.notifier).append(event);
}

/// Os casos de uso das dívidas.
final debtsServiceProvider = Provider<DebtsService>(DebtsService.new);
