import 'package:cajui/src/features/budget/application/income_service.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/receipts/application/capture.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lança as movimentações marcadas de um extrato (RN-707).
///
/// Cada despesa marcada vira um lançamento pelo mesmo caminho de qualquer
/// outro — com as regras do domínio e a chave de idempotência da captura,
/// uma por linha: confirmar o mesmo extrato duas vezes não lança em dobro.
/// Entrada marcada vira recebimento (RN-758). Pagamento de fatura e
/// transferência entre contas próprias nunca viram nada (RN-756, RN-759).
class StatementImport {
  /// Cria o caso de uso sobre os providers de [ref].
  const new(this.ref);

  /// De onde saem o livro e os outros casos de uso.
  final Ref ref;

  /// As linhas que parecem já estar no livro: mesmo valor, dia e lugar
  /// (RN-221). Ficam desmarcadas, mas dá para marcar.
  static Set<int> alreadyThere(List<StatementLine> lines, LedgerBook book) => {
    for (final (index, line) in lines.indexed)
      if (PossibleDuplicate.among(
            book.entries,
            amount: line.amount,
            occurredOn: line.occurredOn,
            description: line.description,
          ) !=
          null)
        index,
  };

  /// As linhas que começam marcadas: as despesas que ainda não estão lá.
  static Set<int> preselected(List<StatementLine> lines, LedgerBook book) {
    final known = alreadyThere(lines, book);
    return {
      for (final (index, line) in lines.indexed)
        if (line.kind == StatementLineKind.expense && !known.contains(index))
          index,
    };
  }

  /// Se a linha pode ser marcada: despesa e entrada; o resto não vira nada.
  static bool isSelectable(StatementLine line) =>
      line.kind == StatementLineKind.expense ||
      line.kind == StatementLineKind.income;

  /// Grava as linhas [selected] de [capture]. Devolve quantas entraram: uma
  /// linha que o domínio recusa — vale sem saldo, data impossível — fica de
  /// fora sem levar as outras junto.
  Future<int> record(Capture capture, Set<int> selected) async {
    final book = await ref.read(ledgerProvider.future);
    var recorded = 0;
    for (final (index, line) in capture.proposal.lines.indexed) {
      if (!selected.contains(index) || !isSelectable(line)) continue;
      if (await _one('${capture.source.id}-$index', line, book)) recorded++;
    }
    return recorded;
  }

  Future<bool> _one(String id, StatementLine line, LedgerBook book) async {
    if (line.kind == StatementLineKind.income) {
      await ref
          .read(incomeServiceProvider)
          .receiveIncome(
            tender: line.paymentKind?.tender ?? Tender.cash,
            amount: line.amount,
            receivedOn: line.occurredOn,
            fromPlan: false,
          );
      return true;
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
            method: _method(book, line.paymentKind),
          ),
        );
    return result.valueOrNull != null;
  }

  static Category? _category(LedgerBook book, String? id) =>
      book.categories.where((category) => category.id == id).firstOrNull;

  /// A forma do tipo que o extrato disse; sem ela, quem decide é o padrão do
  /// lançamento (a última usada, ou Pix).
  static PaymentMethod? _method(LedgerBook book, PaymentMethodKind? kind) =>
      book.methods.where((method) => method.kind == kind).firstOrNull;
}

/// O caso de uso de lançar um extrato.
final statementImportProvider = Provider<StatementImport>(StatementImport.new);
