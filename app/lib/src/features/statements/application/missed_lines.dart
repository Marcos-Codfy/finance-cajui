import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/statements/application/numbered_page.dart';
import 'package:domain/domain.dart';

/// As linhas de uma página que têm cara de movimentação e que a resposta da
/// IA não citou (RN-1104).
///
/// No S22, em 12/10, a IA devolveu 19 das 21 movimentações de um extrato
/// fictício, e as duas que faltaram — a TED recebida e uma farmácia —
/// sumiram caladas. O celular tem o texto da página: confere linha a linha,
/// pede de novo só as que faltaram e, se ainda faltar, a conversa diz.
abstract final class MissedLines {
  /// Os números das linhas de [page] com data e valor que [reply] não citou.
  static List<int> of(NumberedPage page, StatementPageReply reply) {
    final cited = {
      for (final movement in reply.movements) ?movement.sourceLine,
    };
    return [
      for (final (index, line) in page.original.indexed)
        if (StatementShape.isMovement(line) && !cited.contains(index + 1))
          index + 1,
    ];
  }

  /// O pedido de [request] só com as linhas [missed], na ordem. Sem a
  /// imagem: o texto dessas linhas foi lido, só não voltou.
  static StatementPageRequest retry(
    StatementPageRequest request,
    List<int> missed,
  ) => StatementPageRequest(
    lines: [for (final number in missed) request.lines[number - 1]],
    page: request.page,
    pageCount: request.pageCount,
    period: request.period,
    examples: request.examples,
  );

  /// [reply] com as movimentações de [again], a resposta do pedido de
  /// [missed], cada uma de volta ao número dela na página. Só entra a que
  /// cai numa linha que faltava e cujo valor está escrito nela.
  static StatementPageReply merged(
    StatementPageReply reply,
    StatementPageReply again,
    List<int> missed,
    NumberedPage page,
  ) => StatementPageReply(
    movements: [
      ...reply.movements,
      for (final movement in again.movements)
        ?_renumbered(movement, missed, page),
    ],
    period: reply.period ?? again.period,
    partial: reply.partial || again.partial,
  );

  static StatementMovement? _renumbered(
    StatementMovement movement,
    List<int> missed,
    NumberedPage page,
  ) {
    final at = movement.sourceLine;
    final number = at == null ? null : missed.elementAtOrNull(at - 1);
    if (number == null) return null;
    final written = page.original[number - 1];
    if (!ReceiptFieldReader.amountsIn(written).contains(movement.amount)) {
      return null;
    }
    return StatementMovement(
      sourceLine: number,
      day: movement.day,
      month: movement.month,
      year: movement.year,
      description: movement.description,
      amount: movement.amount,
      kind: movement.kind,
      doubtful: movement.doubtful,
      categoryId: movement.categoryId,
      confidence: movement.confidence,
      paymentKind: movement.paymentKind,
    );
  }
}
