import 'dart:convert';

import 'package:meta/meta.dart';

/// Um pedido do modelo para rodar uma ferramenta, com os argumentos que ele
/// escolheu. É **entrada não confiável**: quem roda a ferramenta confere
/// cada argumento de novo.
@immutable
final class ToolCall {
  /// Cria o pedido.
  const new({required this.id, required this.name, required this.arguments});

  /// O identificador que o provedor deu ao pedido; a resposta o cita.
  final String id;

  /// O nome da ferramenta.
  final String name;

  /// Os argumentos, como o modelo os escreveu.
  final Map<String, Object?> arguments;

  /// O pedido como o provedor o devolveu, ou `null` quando não tem a forma
  /// esperada. Argumento que não é JSON vale como nenhum: a ferramenta
  /// responde que faltou, e o modelo tenta de novo.
  static ToolCall? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final function = raw['function'];
    if (function is! Map) return null;
    final name = function['name'];
    if (name is! String || name.isEmpty) return null;
    return ToolCall(
      id: '${raw['id'] ?? ''}',
      name: name,
      arguments: _arguments(function['arguments']),
    );
  }

  static Map<String, Object?> _arguments(Object? raw) {
    if (raw is Map) return raw.cast<String, Object?>();
    if (raw is! String || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? decoded.cast<String, Object?>() : const {};
    } on FormatException {
      return const {};
    }
  }

  /// O pedido como volta para o provedor, no histórico da conversa.
  Map<String, Object?> toJson() => {
    'id': id,
    'type': 'function',
    'function': {'name': name, 'arguments': jsonEncode(arguments)},
  };
}
