import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/receipts/application/statement_import.dart';
import 'package:cajui/src/features/statements/application/statement_reading.dart';
import 'package:domain/domain.dart';

/// As linhas resolvidas de um extrato e as que já estão no Cajui.
typedef ResolvedStatement = ({List<ResolvedLine> lines, Set<int> alreadyThere});

/// Resolve cada linha lida com o que o livro sabe (RN-1109, RN-1110,
/// ADR-030): a memória das respostas, os nomes da casa, o ramo das marcas e
/// o que já foi lançado.
///
/// É refeita a cada resposta: responder grava na memória, e uma resposta só
/// resolve todas as linhas do mesmo lugar. A conta é do domínio
/// (`StatementLineResolver`); aqui só se juntam as peças do livro.
abstract final class StatementResolution {
  /// [reading] resolvido com [book]. [reviewing] são as linhas que a pessoa
  /// mandou corrigir: voltam a ser pergunta de categoria até a resposta.
  static ResolvedStatement of(
    StatementReading reading,
    LedgerBook book, {
    Set<int> reviewing = const {},
  }) {
    final memory = book.learnedAnswers;
    String? categoryOfKind(MerchantKind kind) {
      final id = DefaultCatalog.categoryByMerchantKind[kind];
      return id != null && book.categoriesById.containsKey(id) ? id : null;
    }

    final lines = [
      for (final (i, line) in reading.lines.indexed)
        _reviewed(
          StatementLineResolver.resolve(
            line,
            original: reading.originalOf(line),
            memory: memory,
            household: book.householdNames,
            categoryOfKind: categoryOfKind,
          ),
          reviewing: reviewing.contains(i),
        ),
    ];
    return (
      lines: lines,
      alreadyThere: StatementImport.alreadyThere(reading.lines, book),
    );
  }

  /// A linha em correção (RN-1113) volta a ser pergunta de categoria, com a
  /// categoria que tinha como primeiro palpite.
  static ResolvedLine _reviewed(ResolvedLine line, {required bool reviewing}) {
    if (!reviewing || !line.isExpense) return line;
    return ResolvedLine(
      line: line.line,
      merchantKey: line.merchantKey,
      person: line.person,
      treatment: line.treatment,
      guess: line.line.categoryId ?? line.guess,
      doubts: {...line.doubts, LineDoubt.category},
    );
  }
}
