import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/receipts/application/capture.dart';
import 'package:cajui/src/features/statements/application/statement_batch.dart';
import 'package:cajui/src/features/statements/application/statement_reading.dart';
import 'package:cajui/src/features/statements/application/statement_resolution.dart';
import 'package:domain/domain.dart';

/// Uma fala já passada da conversa do extrato: o que a Juju disse e o que a
/// pessoa respondeu, quando respondeu.
typedef StatementTurn = ({String juju, String? answer});

/// Um cartão que a pergunta "qual cartão?" oferece.
typedef StatementCard = ({String id, String name});

/// Onde está a conversa do extrato com a Juju (RN-1100 a RN-1120).
sealed class StatementTalkState {
  const new _();
}

/// Nenhum extrato em conversa.
final class StatementTalkIdle extends StatementTalkState {
  /// O estado de repouso.
  const new() : super._();
}

/// Lendo: [page] de [of], ou abrindo o arquivo quando [of] é zero.
final class StatementTalkReading extends StatementTalkState {
  /// Cria o estado de leitura.
  const new({this.page = 0, this.of = 0}) : super._();

  /// A página que está sendo lida.
  final int page;

  /// Quantas páginas há para ler.
  final int of;
}

/// A conversa aberta: o resumo dito, os blocos e as dúvidas.
final class StatementTalkOpen extends StatementTalkState {
  /// Cria a conversa.
  const new({
    required this.reading,
    required this.lines,
    required this.digest,
    required this.history,
    required this.categoryOrder,
    this.capture,
    this.cards = const [],
    this.confirmed = const {},
    this.expanded = const {},
    this.reviewing = const {},
    this.skipped = const {},
    this.included = const {},
    this.overrides = const {},
    this.showingAll,
    this.installments,
    this.cardId,
    this.alreadySeen = false,
  }) : super._();

  /// A captura de onde o extrato veio, para fechar depois de lançar.
  final Capture? capture;

  /// O que a leitura achou.
  final StatementReading reading;

  /// As linhas resolvidas com o que o livro sabe agora.
  final List<ResolvedLine> lines;

  /// A organização das linhas para a conversa.
  final StatementDigest digest;

  /// O que já foi dito e respondido.
  final List<StatementTurn> history;

  /// As categorias do cadastro, na ordem de uso: as sugestões da pergunta.
  final List<String> categoryOrder;

  /// Os cartões cadastrados, para a pergunta "qual cartão?".
  final List<StatementCard> cards;

  /// As linhas já conferidas — por bloco ou respondidas. Uma linha que
  /// entra num bloco depois de uma resposta faz o bloco ser perguntado de
  /// novo: nada entra no lote sem a pessoa ver.
  final Set<int> confirmed;

  /// Os blocos com as linhas à mostra, pela categoria; `''` é a lista do
  /// que já estava no Cajui.
  final Set<String> expanded;

  /// As linhas que a pessoa mandou corrigir (RN-1113).
  final Set<int> reviewing;

  /// As linhas tiradas nesta conversa, sem lembrar.
  final Set<int> skipped;

  /// As linhas "já estavam" que a pessoa mandou incluir mesmo assim.
  final Set<int> included;

  /// As respostas que valem só nesta conversa, por linha: as de linha sem
  /// nome que sirva de chave (RN-1116).
  final Map<int, LearnedAnswer> overrides;

  /// A linha cuja pergunta mostra todas as categorias ("Outra").
  final int? showingAll;

  /// O que fazer com as parcelas de outros meses: `null` enquanto não
  /// respondeu (RN-1111).
  final bool? installments;

  /// O cartão das compras no cartão deste extrato, quando há mais de um.
  final String? cardId;

  /// Se a lista do que já estava no Cajui já foi mostrada.
  final bool alreadySeen;

  /// O que a resolução precisa saber do que foi decidido.
  StatementChoices get choices => (
    reviewing: reviewing,
    overrides: overrides,
    included: included,
    installments: installments ?? false,
  );

  /// A mesma conversa, resolvida de novo: [lines] e [digest] novos.
  StatementTalkOpen resolvedAs(
    List<ResolvedLine> lines,
    StatementDigest digest,
  ) => StatementTalkOpen(
    capture: capture,
    reading: reading,
    lines: lines,
    digest: digest,
    history: history,
    categoryOrder: categoryOrder,
    cards: cards,
    confirmed: confirmed,
    expanded: expanded,
    reviewing: reviewing,
    skipped: skipped,
    included: included,
    overrides: overrides,
    showingAll: showingAll,
    installments: installments,
    cardId: cardId,
    alreadySeen: alreadySeen,
  );

  /// A lista do que já estava no Cajui foi vista; [include] são as linhas
  /// que a pessoa mandou incluir mesmo assim.
  StatementTalkOpen seenAlready(Set<int> include, List<StatementTurn> said) =>
      StatementTalkOpen(
        capture: capture,
        reading: reading,
        lines: lines,
        digest: digest,
        history: said,
        categoryOrder: categoryOrder,
        cards: cards,
        confirmed: confirmed,
        expanded: expanded,
        reviewing: reviewing,
        skipped: skipped,
        included: include,
        overrides: overrides,
        showingAll: showingAll,
        installments: installments,
        cardId: cardId,
        alreadySeen: true,
      );

  /// A mesma conversa, com o que mudou.
  StatementTalkOpen copyWith({
    List<StatementTurn>? history,
    Set<int>? confirmed,
    Set<String>? expanded,
    Set<int>? reviewing,
    Set<int>? skipped,
    Set<int>? included,
    Map<int, LearnedAnswer>? overrides,
    int? Function()? showingAll,
    bool? installments,
    String? cardId,
  }) => StatementTalkOpen(
    capture: capture,
    reading: reading,
    lines: lines,
    digest: digest,
    history: history ?? this.history,
    categoryOrder: categoryOrder,
    cards: cards,
    confirmed: confirmed ?? this.confirmed,
    expanded: expanded ?? this.expanded,
    reviewing: reviewing ?? this.reviewing,
    skipped: skipped ?? this.skipped,
    included: included ?? this.included,
    overrides: overrides ?? this.overrides,
    showingAll: showingAll == null ? this.showingAll : showingAll(),
    installments: installments ?? this.installments,
    cardId: cardId ?? this.cardId,
    alreadySeen: alreadySeen,
  );
}

/// Gravando o lote.
final class StatementTalkSaving extends StatementTalkState {
  /// Cria o estado de gravação.
  const new(this.history) : super._();

  /// O que já foi dito.
  final List<StatementTurn> history;
}

/// Lançado: o que entrou, o que o domínio recusou e a conversa de antes,
/// para o desfazer voltar a ela (RN-1119).
final class StatementTalkDone extends StatementTalkState {
  /// Cria o fim da conversa.
  const new({
    required this.talk,
    required this.history,
    required this.outcome,
    required this.refusals,
  }) : super._();

  /// A conversa como estava ao lançar.
  final StatementTalkOpen talk;

  /// O que foi dito, já com o "Lancei".
  final List<StatementTurn> history;

  /// O que o lote gravou, para o desfazer.
  final StatementBatchOutcome outcome;

  /// As linhas recusadas, já com o texto do catálogo (RN-1118).
  final List<String> refusals;
}

/// A leitura não deu: o código do catálogo diz por quê; sem código, não
/// achou movimentação nenhuma.
final class StatementTalkFailed extends StatementTalkState {
  /// Cria a falha.
  const new(this.code, {this.capture}) : super._();

  /// O erro, do catálogo.
  final ErrorCode? code;

  /// A captura, para tentar de novo ou descartar.
  final Capture? capture;
}
