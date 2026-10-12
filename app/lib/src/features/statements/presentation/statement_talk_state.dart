import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/receipts/application/capture.dart';
import 'package:cajui/src/features/statements/application/statement_batch.dart';
import 'package:cajui/src/features/statements/application/statement_reading.dart';
import 'package:domain/domain.dart';

/// Uma fala já passada da conversa do extrato: o que a Juju disse e o que a
/// pessoa respondeu, quando respondeu.
typedef StatementTurn = ({String juju, String? answer});

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
    this.confirmed = const {},
    this.expanded = const {},
    this.reviewing = const {},
    this.skipped = const {},
    this.showingAll,
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

  /// Os blocos já conferidos, pela categoria.
  final Set<String> confirmed;

  /// Os blocos com as linhas à mostra.
  final Set<String> expanded;

  /// As linhas que a pessoa mandou corrigir (RN-1113).
  final Set<int> reviewing;

  /// As linhas tiradas nesta conversa, sem lembrar.
  final Set<int> skipped;

  /// A linha cuja pergunta mostra todas as categorias ("Outra").
  final int? showingAll;

  /// A mesma conversa, com o que mudou.
  StatementTalkOpen copyWith({
    List<ResolvedLine>? lines,
    StatementDigest? digest,
    List<StatementTurn>? history,
    Set<String>? confirmed,
    Set<String>? expanded,
    Set<int>? reviewing,
    Set<int>? skipped,
    int? Function()? showingAll,
  }) => StatementTalkOpen(
    capture: capture,
    reading: reading,
    lines: lines ?? this.lines,
    digest: digest ?? this.digest,
    history: history ?? this.history,
    categoryOrder: categoryOrder,
    confirmed: confirmed ?? this.confirmed,
    expanded: expanded ?? this.expanded,
    reviewing: reviewing ?? this.reviewing,
    skipped: skipped ?? this.skipped,
    showingAll: showingAll == null ? this.showingAll : showingAll(),
  );
}

/// Gravando o lote.
final class StatementTalkSaving extends StatementTalkState {
  /// Cria o estado de gravação.
  const new(this.history) : super._();

  /// O que já foi dito.
  final List<StatementTurn> history;
}

/// Lançado: o que entrou, o que o domínio recusou e se já foi desfeito.
final class StatementTalkDone extends StatementTalkState {
  /// Cria o fim da conversa.
  const new({
    required this.history,
    required this.outcome,
    required this.refusals,
    this.undone = false,
  }) : super._();

  /// O que foi dito, já com o "Lancei".
  final List<StatementTurn> history;

  /// O que o lote gravou, para o desfazer.
  final StatementBatchOutcome outcome;

  /// As linhas recusadas, já com o texto do catálogo (RN-1118).
  final List<String> refusals;

  /// Se o lote já foi desfeito.
  final bool undone;
}

/// A leitura não deu: o código do catálogo diz por quê.
final class StatementTalkFailed extends StatementTalkState {
  /// Cria a falha.
  const new(this.code) : super._();

  /// O erro, do catálogo.
  final ErrorCode code;
}
