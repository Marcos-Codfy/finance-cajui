import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_texts.g.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/receipts/application/capture.dart';
import 'package:cajui/src/features/receipts/application/read_outcome.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:cajui/src/features/receipts/application/shared_item.dart';
import 'package:cajui/src/features/statements/application/statement_page.dart';
import 'package:cajui/src/features/statements/application/statement_reader.dart';
import 'package:cajui/src/features/statements/application/statement_reading.dart';
import 'package:cajui/src/features/statements/application/statement_resolution.dart';
import 'package:cajui/src/features/statements/presentation/statement_talk_state.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Abre o extrato de uma captura para a conversa com a Juju (RN-1101 a
/// RN-1105, RN-1112): lê o arquivo, lê as páginas com a IA e monta o
/// resumo.
///
/// Nunca deixa a conversa presa: qualquer falha — do arquivo, da rede, da
/// IA, ou uma exceção no meio — vira um estado com saída ("Tentar de novo",
/// "Descartar").
class StatementOpening {
  /// Cria a abertura sobre os providers de [ref].
  const new(this.ref);

  /// De onde saem o leitor, o livro e a leitura por página.
  final Ref ref;

  /// A conversa aberta para [capture], ou a falha. [onPage] recebe "página
  /// x de y".
  Future<StatementTalkState> open(
    Capture capture, {
    required void Function(int page, int of) onPage,
  }) async {
    try {
      final read = await _file(capture);
      if (read is ReadFailed) {
        return StatementTalkFailed(read.code, capture: capture);
      }
      final book = await ref.read(ledgerProvider.future);
      final reading = await _pages(read as ReadText, book, onPage);
      if (reading.lines.isEmpty) {
        return StatementTalkFailed(reading.failure, capture: capture);
      }
      return _talk(capture, reading, book);
    } on Exception {
      return StatementTalkFailed(ErrorCode.app01, capture: capture);
    }
  }

  /// O arquivo, ou o texto colado quando o extrato veio como texto.
  Future<ReadOutcome> _file(Capture capture) async {
    final source = capture.source;
    final path = source.filePath;
    if (path == null) return ReadText(source.text);
    return await ref
        .read(receiptReaderProvider)
        .read(SharedFile(id: source.id, path: path, isPdf: source.isPdf));
  }

  Future<StatementReading> _pages(
    ReadText read,
    LedgerBook book,
    void Function(int page, int of) onPage,
  ) => ref
      .read(statementReaderProvider)
      .read(
        StatementPage.ofRead(read),
        knowsCategory: book.categoriesById.containsKey,
        pageCount: read.pageCount,
        // Exemplo de pessoa nunca vai à IA, nem pelo nome (RN-1107).
        examples: {
          for (final MapEntry(:key, :value)
              in book.learnedAnswers.examples.entries)
            if (!LearnedRules.looksLikePerson(key)) key: value,
        },
        household: book.householdNames,
        onPage: onPage,
      );

  StatementTalkOpen _talk(
    Capture capture,
    StatementReading reading,
    LedgerBook book,
  ) {
    final resolved = StatementResolution.of(reading, book);
    final digest = StatementDigest.of(
      resolved.lines,
      alreadyThere: resolved.alreadyThere,
    );
    return StatementTalkOpen(
      capture: capture,
      reading: reading,
      lines: resolved.lines,
      digest: digest,
      categoryOrder: [for (final category in book.categories) category.id],
      cards: [for (final card in book.cards) (id: card.id, name: card.name)],
      history: [
        (
          juju: [StatementWords.summary(digest), ..._notes(reading)].join(' '),
          answer: null,
        ),
      ],
    );
  }

  /// O que ficou de fora da leitura: páginas além do teto, as que falharam,
  /// as que passaram de 400 movimentações, e as lidas em parte — essas,
  /// com o texto do catálogo (E-AI-05).
  static List<String> _notes(StatementReading reading) => [
    ?StatementWords.pages(
      read: reading.pagesRead,
      total: reading.pageCount,
      failed: reading.failedPages,
      beyond: reading.beyondLimit,
      unread: reading.unreadLines,
    ),
    for (final page in reading.partialPages)
      ErrorTexts.of(ErrorCode.ai05).fill({'página': '$page'}).message,
  ];
}
