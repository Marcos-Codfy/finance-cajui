import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:server/src/auth/secure_random.dart';

/// A chave da casa (ADR-020): **um segredo só**, o mesmo em todos os
/// aparelhos do dono, no lugar do cadastro de aparelho com código.
///
/// É uma casa de uma pessoa. Cadastrar cada celular por SSH, assinar
/// desafio com biometria e parear o navegador com código de dois minutos
/// protegia contra um risco que o dono não tem e cobrava dele uma
/// cerimônia a cada aparelho. A chave vai compilada no APK, é digitada uma
/// vez no navegador, e o servidor só guarda o **hash** dela: quem ler o
/// disco não acha nada que sirva para entrar.
///
/// Chega por credencial cifrada do systemd, como a chave dos dados. Sem a
/// credencial o servidor sobe do mesmo jeito, mas ninguém entra: a
/// autenticação antiga, por aparelho cadastrado, saiu em 11/10 (ADR-024).
final class HouseholdKey {
  /// Cria a chave a partir do segredo em claro, que não fica guardado.
  new(String key) : _hash = SecureRandom.hash(key.trim());

  /// O nome da credencial que o systemd entrega ao serviço.
  static const credentialName = 'cajui-access-key';

  /// Chave mais curta que isto é um erro de configuração, não uma chave.
  static const minLength = 16;

  final String _hash;

  /// A chave lida da credencial do systemd, ou do arquivo [file] quando
  /// dado — para rodar fora de um serviço. `null` quando não há chave.
  static HouseholdKey? load({
    required Map<String, String> environment,
    String? file,
  }) {
    final directory = environment['CREDENTIALS_DIRECTORY'];
    final path =
        file ?? (directory == null ? null : p.join(directory, credentialName));
    if (path == null) return null;
    final source = File(path);
    if (!source.existsSync()) return null;
    final key = source.readAsStringSync().trim();
    return key.length < minLength ? null : HouseholdKey(key);
  }

  /// Se [presented] é a chave. A comparação percorre o hash inteiro sempre,
  /// para o tempo de resposta não contar quantos caracteres bateram.
  bool matches(String presented) {
    final other = SecureRandom.hash(presented.trim());
    var difference = 0;
    for (var i = 0; i < _hash.length; i++) {
      difference |= _hash.codeUnitAt(i) ^ other.codeUnitAt(i);
    }
    return difference == 0;
  }
}
