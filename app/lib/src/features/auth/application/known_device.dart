import 'package:meta/meta.dart';

/// Um aparelho com acesso, como a lista o mostra.
@immutable
final class KnownDevice {
  /// Cria o aparelho.
  const new({required this.id, required this.name, required this.isWeb});

  /// Lê o aparelho como o servidor o lista. Campo que falte vira o padrão:
  /// uma linha sem nome na lista ainda deixa descadastrar o aparelho.
  factory read(Map<Object?, Object?> json) => KnownDevice(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? 'Aparelho',
    isWeb: json['kind'] == 'web',
  );

  /// O identificador, derivado da chave pública dele.
  final String id;

  /// O nome dado no cadastro.
  final String name;

  /// Se é um acesso de navegador, que **só lê** (RN-906).
  final bool isWeb;
}
