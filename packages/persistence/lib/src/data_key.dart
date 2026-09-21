import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

/// A chave de dados: os 32 bytes que abrem o registro.
///
/// Ela chega **por arquivo**, nunca por variável de ambiente nem por
/// argumento de linha de comando — os dois aparecem na lista de processos.
/// Em produção o arquivo é uma credencial do systemd, que só existe em
/// memória e só para o serviço (ADR-005).
abstract final class DataKey {
  /// O nome da credencial que o systemd entrega ao serviço.
  static const credentialName = 'cajui-data-key';

  static const _length = 32;

  /// Lê a chave do arquivo [path], que guarda os 32 bytes em base64.
  static List<int> read(String path) {
    final bytes = base64Decode(File(path).readAsStringSync().trim());
    if (bytes.length != _length) {
      throw const FormatException(
        'A chave de dados precisa ter $_length bytes.',
      );
    }
    return bytes;
  }

  /// O caminho da credencial entregue pelo systemd, a partir de
  /// `CREDENTIALS_DIRECTORY`; nulo fora de um serviço. A variável guarda só
  /// o **caminho** de uma pasta em memória — a chave em si nunca fica no
  /// ambiente.
  static String? systemdCredentialPath(Map<String, String> environment) {
    final directory = environment['CREDENTIALS_DIRECTORY'];
    return directory == null ? null : p.join(directory, credentialName);
  }

  /// Gera uma chave nova com o gerador criptográfico do sistema, em base64.
  static String generate() {
    final random = Random.secure();
    return base64Encode([
      for (var i = 0; i < _length; i++) random.nextInt(256),
    ]);
  }
}
