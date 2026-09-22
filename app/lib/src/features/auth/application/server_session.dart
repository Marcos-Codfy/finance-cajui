import 'dart:convert';

import 'package:cryptography/dart.dart';
import 'package:meta/meta.dart';

/// Uma sessão aberta no servidor: o portador e até quando ele vale.
///
/// Fica **só na memória**. Sessão de aparelho dura pouco (ADR-008), e o que
/// prova quem somos não é ela, e sim a chave do Keystore: perder a sessão
/// custa um desafio novo, não um cadastro novo.
@immutable
final class ServerSession {
  /// Cria a sessão [token], válida até [expiresAt].
  const new({required this.token, required this.expiresAt});

  /// O portador, que vai no cabeçalho `Authorization`.
  final String token;

  /// Quando ela deixa de valer.
  final DateTime expiresAt;

  /// Uma folga antes do fim: sessão que vence no meio de uma pergunta vira
  /// erro para quem só queria conversar.
  static const margin = Duration(seconds: 30);

  /// Se ainda serve em [now].
  bool isValidAt(DateTime now) => now.add(margin).isBefore(expiresAt);
}

/// O identificador deste aparelho para o servidor.
///
/// É **derivado da chave pública**, e não sorteado: a chave do Keystore já é
/// a identidade, então não há um segundo dado a guardar, a sincronizar nem a
/// perder. Apagou a chave, é outro aparelho — que é a verdade.
String deviceIdOf(List<int> publicKey) {
  final digest = const DartSha256().hashSync(publicKey);
  return base64Url.encode(digest.bytes).substring(0, 32);
}
