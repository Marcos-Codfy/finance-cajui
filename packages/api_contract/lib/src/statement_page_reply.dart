import 'package:api_contract/src/entry_codec.dart';
import 'package:api_contract/src/statement_movement.dart';
import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// A resposta da leitura de uma página de extrato, em
/// `POST /v1/statements/read-part` (ADR-030): as movimentações que passaram
/// na conferência do servidor, o mês do extrato quando a página o diz, e se
/// a página foi lida só em parte.
@immutable
final class StatementPageReply {
  /// Cria a resposta.
  const new({required this.movements, this.period, this.partial = false});

  /// A resposta em [json]. Movimentação que não se lê cai fora sozinha, e
  /// período fora do formato vale como nenhum: o resto da página continua
  /// valendo.
  factory fromJson(
    Map<String, Object?> json, {
    required bool Function(String id) knowsCategory,
  }) {
    final raw = json['movements'];
    final movements = [
      for (final item in raw is List ? raw : const <Object?>[])
        ?StatementMovement.tryParse(item, knowsCategory: knowsCategory),
    ];
    return StatementPageReply(
      movements: movements.take(maxMovements).toList(),
      period: _period(json['period']),
      partial: json['partial'] == true || movements.length > maxMovements,
    );
  }

  /// Quantas movimentações uma página rende (RN-1104). O que passar disso
  /// marca a página como lida em parte: nunca é cortado em silêncio.
  static const maxMovements = 60;

  /// As movimentações, na ordem da página.
  final List<StatementMovement> movements;

  /// O mês do extrato, quando a página o escreve.
  final BudgetMonth? period;

  /// Se a página foi lida só em parte: a resposta da IA cortou duas vezes,
  /// ou passou do teto de movimentações (RN-1103, RN-1104). O resumo
  /// avisa com `E-AI-05`.
  final bool partial;

  /// A resposta como vai pela rede.
  Map<String, Object?> toJson() => {
    'movements': [for (final movement in movements) movement.toJson()],
    'period': period?.toString(),
    if (partial) 'partial': true,
  };

  static BudgetMonth? _period(Object? raw) {
    if (raw is! String) return null;
    try {
      return EntryCodec.parseMonth(raw);
    } on FormatException {
      return null;
    }
  }
}
