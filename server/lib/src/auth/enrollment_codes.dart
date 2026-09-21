import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:server/src/auth/secure_random.dart';

/// O código que cadastra um aparelho novo (ADR-008 · T-03).
///
/// Só nasce por linha de comando, **dentro da VM**: quem não tem SSH no
/// servidor não cadastra aparelho — o SSH é a prova de identidade. O código
/// vale 10 minutos e uma vez só, e o disco guarda apenas o hash dele.
final class EnrollmentCodes {
  /// Cria o gerenciador sobre a pasta de dados [directory].
  new(Directory directory, {DateTime Function()? now})
    : _file = File(p.join(directory.path, 'enrollment.json')),
      _now = now ?? DateTime.now;

  /// Por quanto tempo um código vale.
  static const validity = Duration(minutes: 10);

  final File _file;
  final DateTime Function() _now;

  /// Emite um código novo, invalidando o anterior. Devolve o código em claro
  /// — é a única vez em que ele existe assim.
  String issue() {
    final code = SecureRandom.code(10);
    _file.parent.createSync(recursive: true);
    _file.writeAsStringSync(
      jsonEncode({
        'hash': SecureRandom.hash(code),
        'expiresAt': _now().add(validity).toUtc().toIso8601String(),
      }),
      flush: true,
    );
    return code;
  }

  /// Consome [code]: devolve se ele era o código vigente e dentro do prazo.
  /// Acertando ou vencido, o código deixa de existir.
  bool consume(String code) {
    if (!_file.existsSync()) return false;
    final stored = jsonDecode(_file.readAsStringSync()) as Map<String, Object?>;
    final expired = _now().isAfter(DateTime.parse('${stored['expiresAt']}'));
    final matches = stored['hash'] == SecureRandom.hash(code.toUpperCase());
    if (expired || matches) _file.deleteSync();
    return matches && !expired;
  }
}
