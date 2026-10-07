import 'package:meta/meta.dart';

/// Uma ferramenta que o modelo pode pedir: o nome, para que serve e a forma
/// dos argumentos, em JSON Schema — é assim que o provedor a descreve ao
/// modelo.
@immutable
final class ChatTool {
  /// Cria a descrição da ferramenta.
  const new({
    required this.name,
    required this.description,
    required this.parameters,
  });

  /// O nome, que é o que o modelo cita ao pedir.
  final String name;

  /// Para que serve, nas palavras que o modelo lê.
  final String description;

  /// A forma dos argumentos.
  final Map<String, Object?> parameters;

  /// A ferramenta como vai para o provedor.
  Map<String, Object?> toJson() => {
    'type': 'function',
    'function': {
      'name': name,
      'description': description,
      'parameters': parameters,
    },
  };
}
