import 'package:meta/meta.dart';

/// O que o assistente **fez** numa conversa — lançou, cancelou, registrou
/// renda —, dito ao app em separado do texto.
///
/// O texto da IA conta a história; isto é o fato, com identificador: é o
/// que deixa a tela oferecer "Desfazer" sem adivinhar nada a partir da
/// frase.
@immutable
final class AssistantAction {
  const new _({
    required this.kind,
    required this.id,
    required this.label,
    required this.amountCents,
    this.debtId,
  });

  /// Uma despesa lançada.
  const new recorded({
    required String id,
    required String label,
    required int amountCents,
  }) : this._(kind: 'recorded', id: id, label: label, amountCents: amountCents);

  /// Um lançamento cancelado.
  const new cancelled({
    required String id,
    required String label,
    required int amountCents,
  }) : this._(
         kind: 'cancelled',
         id: id,
         label: label,
         amountCents: amountCents,
       );

  /// Uma renda registrada.
  const new income({
    required String id,
    required String label,
    required int amountCents,
  }) : this._(kind: 'income', id: id, label: label, amountCents: amountCents);

  /// Um abatimento de dívida: o lançamento [id], que pagou a dívida
  /// [debtId]. Desfazer cancela o lançamento e devolve o saldo (BL-117).
  const new paidDown({
    required String id,
    required String label,
    required int amountCents,
    required String debtId,
  }) : this._(
         kind: 'paidDown',
         id: id,
         label: label,
         amountCents: amountCents,
         debtId: debtId,
       );

  /// `recorded`, `cancelled`, `income` ou `paidDown`.
  final String kind;

  /// O identificador do lançamento ou do recebimento.
  final String id;

  /// O que a tela mostra: a descrição.
  final String label;

  /// O valor, em centavos.
  final int amountCents;

  /// A dívida abatida, só no `paidDown`.
  final String? debtId;

  /// A ação como vai para o app.
  Map<String, Object?> toJson() => {
    'kind': kind,
    'id': id,
    'label': label,
    'amountCents': amountCents,
    'debtId': ?debtId,
  };
}
