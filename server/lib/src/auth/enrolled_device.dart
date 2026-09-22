import 'package:meta/meta.dart';
import 'package:server/src/auth/session_scope.dart';

/// Um aparelho cadastrado, como a pessoa o vê na lista.
///
/// Não carrega chave nenhuma — nem a pública. Quem lista os próprios
/// aparelhos quer saber **o que está com acesso**, e para isso bastam o nome
/// e o que ele pode fazer.
@immutable
final class EnrolledDevice {
  /// Cria o aparelho.
  const new({required this.id, required this.name, required this.scope});

  /// O identificador, derivado da chave pública dele.
  final String id;

  /// O nome dado no cadastro: "Meu S22", "Notebook".
  final String name;

  /// O que a sessão dele pode fazer.
  final SessionScope scope;

  /// O que a lista mostra.
  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'kind': scope == SessionScope.webReadOnly ? 'web' : 'device',
  };
}
