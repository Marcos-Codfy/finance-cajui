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

  /// `recorded`, `cancelled` ou `income`.
  final String kind;

  /// O identificador do lançamento ou do recebimento.
  final String id;

  /// O que a tela mostra: a descrição.
  final String label;

  /// O valor, em centavos.
  final int amountCents;

  /// A ação como vai para o app.
  Map<String, Object?> toJson() => {
    'kind': kind,
    'id': id,
    'label': label,
    'amountCents': amountCents,
  };
}
