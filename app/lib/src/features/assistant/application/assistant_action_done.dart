import 'package:meta/meta.dart';

/// O que o assistente fez no livro ao responder: lançou, cancelou,
/// registrou renda (ADR-021). Vem do servidor, separado do texto — é o que
/// deixa a tela oferecer "Desfazer" sem adivinhar nada a partir da frase.
@immutable
final class AssistantActionDone {
  /// Cria a ação.
  const new({
    required this.kind,
    required this.id,
    required this.label,
    required this.amountCents,
    this.debtId,
  });

  /// Lê a ação de [json], como vem da API.
  factory fromJson(Map<String, Object?> json) => AssistantActionDone(
    kind: json['kind'] as String? ?? '',
    id: json['id'] as String? ?? '',
    label: json['label'] as String? ?? '',
    amountCents: json['amountCents'] as int? ?? 0,
    debtId: json['debtId'] as String?,
  );

  /// `recorded`, `cancelled` ou `income`.
  final String kind;

  /// O identificador do lançamento ou do recebimento.
  final String id;

  /// A descrição, como a tela a mostra.
  final String label;

  /// O valor, em centavos.
  final int amountCents;

  /// Se dá para desfazer daqui: só o que foi lançado. Cancelar não se
  /// desfaz (RN-208), e renda se corrige no plano.
  bool get isUndoable => kind == 'recorded' || kind == 'paidDown';

  /// A dívida que o lançamento abateu, no `paidDown`: desfazer devolve o
  /// saldo dela também (BL-117).
  final String? debtId;
}
