import 'dart:io';

import 'package:domain/domain.dart';
import 'package:path/path.dart' as p;
import 'package:persistence/persistence.dart';
import 'package:server/src/ai/ai_receipt_classifier.dart';
import 'package:server/src/ai/circuit_breaker.dart';
import 'package:server/src/ai/deepseek_chat_client.dart';
import 'package:server/src/ai/token_budget.dart';
import 'package:server/src/app.dart';
import 'package:server/src/auth/enrollment_codes.dart';
import 'package:server/src/auth/session_book.dart';
import 'package:server/src/system_clock.dart';
import 'package:shelf/shelf_io.dart' as io;

/// O servidor do Cajui.
///
/// ```text
/// server serve  <pasta-de-dados> [--key-file <arquivo>]
/// server enroll <pasta-de-dados>
/// ```
///
/// `serve` sobe a API. `enroll` emite o código que cadastra um aparelho novo
/// — só por aqui, dentro da VM (ADR-008).
Future<void> main(List<String> arguments) async {
  if (arguments.length < 2) {
    stderr.writeln('uso: server serve|enroll <pasta-de-dados> [--key-file f]');
    exitCode = 64;
    return;
  }
  final data = Directory(arguments[1]);
  switch (arguments.first) {
    case 'enroll':
      stdout
        ..writeln('Código de cadastro: ${EnrollmentCodes(data).issue()}')
        ..writeln('Vale por 10 minutos, uma única vez.');
    case 'serve':
      await _serve(data, _keyFile(arguments));
    default:
      exitCode = 64;
  }
}

/// A chave vem da credencial do systemd; `--key-file` existe para rodar fora
/// de um serviço, em desenvolvimento.
String _keyFile(List<String> arguments) {
  final flag = arguments.indexOf('--key-file');
  final path = flag >= 0 && flag + 1 < arguments.length
      ? arguments[flag + 1]
      : DataKey.systemdCredentialPath(Platform.environment);
  if (path == null) {
    throw StateError('Sem chave de dados: use --key-file ou uma credencial.');
  }
  return path;
}

/// Com a credencial da DeepSeek, a IA entra por cima das regras locais; sem
/// ela, o servidor sobe só com as regras, e tudo continua funcionando.
ReceiptClassifier _classifier(EventStore store) {
  final directory = Platform.environment['CREDENTIALS_DIRECTORY'];
  final keyFile = directory == null
      ? null
      : File(p.join(directory, DeepSeekChatClient.credentialName));
  if (keyFile == null || !keyFile.existsSync()) {
    stdout.writeln('sem credencial da IA: classificando só pelas regras locais');
    return const RuleBasedClassifier();
  }
  return AiReceiptClassifier(
    client: DeepSeekChatClient(apiKey: keyFile.readAsStringSync().trim()),
    budget: TokenBudget(store, monthlyLimit: 2000000),
    breaker: CircuitBreaker(),
  );
}

Future<void> _serve(Directory data, String keyFile) async {
  final store = await FileEventStore.open(
    data,
    AesGcmRecordCipher(DataKey.read(keyFile)),
  );
  final app = App(
    store: store,
    dataDirectory: data,
    clock: const SystemClock(),
    log: stdout.writeln,
    sessions: SessionBook(),
    classifier: _classifier(store),
  );
  // Só na própria máquina: quem recebe a internet é o Caddy (ADR-003 · T-36).
  final host = Platform.environment['HOST'] ?? '127.0.0.1';
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await io.serve(app.handler, InternetAddress(host), port);
  stdout.writeln('ouvindo em http://${server.address.host}:${server.port}');
}
