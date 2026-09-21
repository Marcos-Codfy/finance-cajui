import 'dart:convert';

import 'package:meta/meta.dart';

/// Um evento do registro: um fato que aconteceu, e que nunca mais muda.
///
/// Corrigir um lançamento não altera o evento dele: acrescenta outro, de
/// correção. É o que torna cada número do painel explicável — e o que deixa
/// o backup de ontem ser um prefixo exato do de hoje.
@immutable
final class StoredEvent {
  /// Cria o evento.
  const new({
    required this.seq,
    required this.id,
    required this.type,
    required this.at,
    required this.schema,
    required this.payload,
  });

  /// Reconstrói o evento [seq] a partir do JSON decifrado de uma linha.
  factory fromJson(int seq, Map<String, Object?> json) => StoredEvent(
    seq: seq,
    id: json['id']! as String,
    type: json['type']! as String,
    at: DateTime.parse(json['at']! as String),
    schema: json['schema']! as int,
    payload: (json['payload']! as Map).cast<String, Object?>(),
  );

  /// A posição no registro, a partir de 1, sem buracos.
  final int seq;

  /// O identificador do evento, criado por quem o originou. É também a chave
  /// de idempotência: o mesmo comando enviado duas vezes não vira dois
  /// eventos.
  final String id;

  /// O tipo do evento: `entry.created`, `voucher.adjusted`.
  final String type;

  /// O instante em que foi gravado, em UTC.
  final DateTime at;

  /// A versão do formato do [payload]. Evento gravado nunca é reescrito:
  /// quando o formato muda, o leitor aprende a ler as versões antigas.
  final int schema;

  /// O conteúdo do evento.
  final Map<String, Object?> payload;

  /// O que vai cifrado dentro da linha. O [seq] fica de fora: ele vai em
  /// claro, para a cadeia poder ser conferida sem a chave.
  String toPlaintext() => jsonEncode({
    'id': id,
    'type': type,
    'at': at.toUtc().toIso8601String(),
    'schema': schema,
    'payload': payload,
  });
}
