import 'package:domain/domain.dart';
import 'package:flutter/foundation.dart';

/// O retrato que o Cajui deixa para fora do app: o widget da tela inicial
/// mostra o número, e o aviso de domingo conta o que ficou para revisar
/// (ADR-025).
///
/// Vai pronto, já em texto: do lado nativo não há conta nem regra, só um
/// desenho do que o app disse.
@immutable
final class HomeSnapshot {
  /// Cria o retrato.
  const new({
    required this.label,
    required this.amount,
    required this.caption,
    required this.validUntil,
    required this.reviewDates,
  });

  /// O que o número é: "Sobra de outubro".
  final String label;

  /// O número, já formatado: "R$ 312,40".
  final String amount;

  /// A frase de baixo, no tom do painel.
  final String caption;

  /// O último dia em que o número vale: o fim do mês. Depois dele, o widget
  /// pede para abrir o app, em vez de mostrar o número do mês passado como
  /// se fosse deste.
  final LocalDate validUntil;

  /// O dia de cada lançamento que espera revisão (RN-870). É o dia, e não a
  /// contagem: no domingo, o lado nativo conta só os dos últimos sete dias,
  /// mesmo que o app não tenha sido aberto desde quarta.
  final List<LocalDate> reviewDates;

  @override
  bool operator ==(Object other) =>
      other is HomeSnapshot &&
      other.label == label &&
      other.amount == amount &&
      other.caption == caption &&
      other.validUntil == validUntil &&
      listEquals(other.reviewDates, reviewDates);

  @override
  int get hashCode =>
      Object.hash(label, amount, caption, validUntil, reviewDates.length);

  /// O que atravessa o canal.
  Map<String, Object?> toMap() => {
    'label': label,
    'amount': amount,
    'caption': caption,
    'validUntil': '$validUntil',
    'reviewDates': [for (final day in reviewDates) '$day'],
  };
}
