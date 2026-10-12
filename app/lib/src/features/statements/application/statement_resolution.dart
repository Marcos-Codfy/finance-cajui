import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/statements/application/statement_matches.dart';
import 'package:cajui/src/features/statements/application/statement_reading.dart';
import 'package:domain/domain.dart';

/// As linhas resolvidas de um extrato e as que já estão no Cajui.
typedef ResolvedStatement = ({List<ResolvedLine> lines, Set<int> alreadyThere});

/// O que a conversa decidiu até agora e que muda a resolução: as linhas em
/// correção, as respostas que valem só nesta conversa, as linhas "já
/// estavam" que a pessoa mandou incluir e o que fazer com as parcelas.
typedef StatementChoices = ({
  Set<int> reviewing,
  Map<int, LearnedAnswer> overrides,
  Set<int> included,
  bool installments,
});

/// Resolve cada linha lida com o que o livro sabe (RN-1109 a RN-1112,
/// ADR-030): a memória das respostas, os nomes da casa, o ramo das marcas e
/// o que já foi lançado.
///
/// É refeita a cada resposta: responder grava na memória, e uma resposta só
/// resolve todas as linhas do mesmo lugar. A conta é do domínio
/// (`StatementLineResolver`); aqui só se juntam as peças do livro.
abstract final class StatementResolution {
  /// Nada decidido ainda.
  static const StatementChoices none = (
    reviewing: {},
    overrides: {},
    included: {},
    installments: false,
  );

  /// [reading] resolvido com [book] e com as decisões [choices].
  static ResolvedStatement of(
    StatementReading reading,
    LedgerBook book, {
    StatementChoices choices = none,
  }) {
    final memory = LearnedAnswers.of(book.answerHistory);
    String? categoryOfKind(MerchantKind kind) {
      final id = DefaultCatalog.categoryByMerchantKind[kind];
      return id != null && book.categoriesById.containsKey(id) ? id : null;
    }

    final lines = [
      for (final (i, line) in reading.lines.indexed)
        _decided(
          StatementLineResolver.resolve(
            line,
            original: reading.originalOf(line),
            memory: memory,
            household: book.householdNames,
            categoryOfKind: categoryOfKind,
          ),
          reviewing: choices.reviewing.contains(i),
          installments: choices.installments,
          answer: choices.overrides[i],
        ),
    ];
    final there = StatementMatches.of(lines, book)..removeAll(choices.included);
    return (lines: lines, alreadyThere: there);
  }

  /// A linha em correção (RN-1113) volta a ser pergunta de categoria, com a
  /// categoria que tinha como primeiro palpite. Com as parcelas aceitas
  /// (RN-1111), a parcela vira uma compra como as outras.
  ///
  /// [answer] é a resposta que vale só para esta linha: a de linha sem nome
  /// que sirva de chave, que não pode ser lembrada (RN-1116).
  static ResolvedLine _decided(
    ResolvedLine line, {
    required bool reviewing,
    required bool installments,
    LearnedAnswer? answer,
  }) {
    final treatment = answer?.treatment ?? line.treatment;
    final category = answer?.categoryId ?? line.line.categoryId;
    final doubts = {
      ...line.doubts,
      if (reviewing && line.isExpense && answer?.categoryId == null)
        LineDoubt.category,
    };
    if (installments) doubts.remove(LineDoubt.installment);
    if (answer?.treatment != null) doubts.remove(LineDoubt.kind);
    if (answer?.categoryId != null) doubts.remove(LineDoubt.category);
    if (treatment == LineTreatment.expense && category == null) {
      doubts.add(LineDoubt.category);
    }
    return ResolvedLine(
      line: _withCategory(line.line, category),
      merchantKey: line.merchantKey,
      contentKey: line.contentKey,
      person: line.person,
      treatment: treatment,
      installment: line.installment,
      guess: line.line.categoryId ?? line.guess,
      doubts: doubts,
    );
  }

  static StatementLine _withCategory(StatementLine line, String? category) =>
      category == line.categoryId
      ? line
      : StatementLine(
          occurredOn: line.occurredOn,
          description: line.description,
          amount: line.amount,
          kind: line.kind,
          categoryId: category,
          paymentKind: line.paymentKind,
          doubtful: line.doubtful,
          confidence: line.confidence,
          page: line.page,
          sourceLine: line.sourceLine,
        );
}
