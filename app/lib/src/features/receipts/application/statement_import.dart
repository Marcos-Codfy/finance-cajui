import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/budget/application/income_service.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/receipts/application/capture.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O que aconteceu com as linhas marcadas: as que entraram e as que o
/// domínio recusou, com o motivo.
typedef StatementOutcome = ({Set<int> recorded, Map<int, Failure> refused});

/// Lança as movimentações marcadas de um extrato (RN-707).
///
/// Cada despesa marcada vira um lançamento pelo mesmo caminho de qualquer
/// outro — com as regras do domínio e a chave de idempotência da captura,
/// uma por linha: confirmar o mesmo extrato duas vezes não lança em dobro.
/// Entrada marcada vira recebimento (RN-758). Pagamento de fatura e
/// transferência entre contas próprias só viram despesa se a leitura estava
/// em dúvida e a pessoa marcou (RN-756, RN-757, RN-759).
class StatementImport {
  /// Cria o caso de uso sobre os providers de [ref].
  const new(this.ref);

  /// De onde saem o livro e os outros casos de uso.
  final Ref ref;

  /// As linhas que parecem já estar no livro: despesa com o mesmo valor e a
  /// data a até dois dias de um lançamento; entrada, de um recebimento. O
  /// banco escreve o nome do lugar do jeito dele, então o nome não conta.
  /// Ficam desmarcadas, mas dá para marcar.
  static Set<int> alreadyThere(List<StatementLine> lines, LedgerBook book) => {
    for (final (index, line) in lines.indexed)
      if (_isKnown(line, book)) index,
  };

  static bool _isKnown(StatementLine line, LedgerBook book) =>
      line.kind == StatementLineKind.income
      ? PossibleDuplicate.receivedNear(
              book.receipts,
              amount: line.amount,
              receivedOn: line.occurredOn,
            ) !=
            null
      : PossibleDuplicate.near(
              book.entries,
              amount: line.amount,
              occurredOn: line.occurredOn,
            ) !=
            null;

  /// As linhas que começam marcadas: as despesas certas que ainda não estão
  /// lá, e cuja forma de pagamento se sabe sem adivinhar.
  static Set<int> preselected(List<StatementLine> lines, LedgerBook book) {
    final known = alreadyThere(lines, book);
    return {
      for (final (index, line) in lines.indexed)
        if (line.kind == StatementLineKind.expense &&
            !line.doubtful &&
            !known.contains(index) &&
            _hasClearMethod(line, book))
          index,
    };
  }

  /// Se a linha pode ser marcada: despesa, entrada, e o que estava em dúvida.
  static bool isSelectable(StatementLine line) =>
      line.doubtful ||
      line.kind == StatementLineKind.expense ||
      line.kind == StatementLineKind.income;

  /// Por onde a despesa da linha saiu. O extrato é de uma conta: sem a forma
  /// escrita, é débito ou Pix — **nunca** a última forma usada, que podia ser
  /// o vale (RN-111) ou um cartão. Vale e cartão só quando a linha diz.
  static PaymentMethod? methodFor(StatementLine line, LedgerBook book) {
    PaymentMethod? of(PaymentMethodKind kind) =>
        book.methods.where((method) => method.kind == kind).firstOrNull;
    return switch (line.paymentKind) {
      final PaymentMethodKind kind => of(kind),
      null => of(PaymentMethodKind.debit) ?? of(PaymentMethodKind.pix),
    };
  }

  /// Linha de cartão com mais de um cartão cadastrado não diz qual: aparece,
  /// mas não vem marcada.
  static bool _hasClearMethod(StatementLine line, LedgerBook book) {
    if (line.paymentKind != PaymentMethodKind.creditCard) {
      return methodFor(line, book) != null;
    }
    return book.cards.length == 1;
  }

  /// O salário que a entrada da linha parece ser (RN-758); nulo quando é
  /// entrada avulsa.
  static IncomeSource? salaryOf(StatementLine line, LedgerBook book) =>
      _tender(line) == Tender.cash
      ? BookFinances.of(book).salaryLike(line.amount, line.occurredOn)
      : null;

  static Tender _tender(StatementLine line) =>
      line.paymentKind?.tender ?? Tender.cash;

  /// Grava as linhas [selected] de [capture]. Uma linha que o domínio recusa
  /// — vale sem saldo, categoria que o vale não paga — fica de fora sem
  /// levar as outras junto, e volta com o motivo.
  Future<StatementOutcome> record(Capture capture, Set<int> selected) async {
    final book = await ref.read(ledgerProvider.future);
    final recorded = <int>{};
    final refused = <int, Failure>{};
    for (final (index, line) in capture.proposal.lines.indexed) {
      if (!selected.contains(index) || !isSelectable(line)) continue;
      final id = '${capture.source.id}-$index';
      final failure = await _one(id, line, book);
      failure == null ? recorded.add(index) : refused[index] = failure;
    }
    return (recorded: recorded, refused: refused);
  }

  Future<Failure?> _one(String id, StatementLine line, LedgerBook book) async {
    if (line.kind == StatementLineKind.income && !line.doubtful) {
      await ref
          .read(incomeServiceProvider)
          .receiveIncome(
            tender: _tender(line),
            amount: line.amount,
            receivedOn: line.occurredOn,
            salaryId: salaryOf(line, book)?.id,
            id: id,
          );
      return null;
    }
    final result = await ref
        .read(ledgerProvider.notifier)
        .record(
          EntryDraft(
            captureId: id,
            amountCents: line.amount.cents,
            description: line.description,
            occurredOn: line.occurredOn,
            category: _category(book, line.categoryId),
            method: methodFor(line, book),
          ),
        );
    return result.failureOrNull;
  }

  static Category? _category(LedgerBook book, String? id) =>
      book.categories.where((category) => category.id == id).firstOrNull;
}

/// O caso de uso de lançar um extrato.
final statementImportProvider = Provider<StatementImport>(StatementImport.new);
