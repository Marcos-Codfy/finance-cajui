import 'dart:io';

import 'package:domain/domain.dart';
import 'package:path/path.dart' as p;
import 'package:persistence/persistence.dart';
import 'package:server/src/ai/ai_receipt_classifier.dart';
import 'package:server/src/ai/circuit_breaker.dart';
import 'package:server/src/ai/deepseek_chat_client.dart';
import 'package:server/src/ai/token_budget.dart';
import 'package:server/src/app.dart';
import 'package:server/src/assistant/assistant_service.dart';
import 'package:server/src/auth/enrollment_codes.dart';
import 'package:server/src/auth/household_key.dart';
import 'package:server/src/auth/session_book.dart';
import 'package:server/src/system_clock.dart';
import 'package:shelf/shelf_io.dart' as io;

/// O servidor do Cajui.
///
/// ```text
/// server serve  <pasta-de-dados> [--key-file <arquivo>] [--access-key-file <arquivo>]
/// server enroll <pasta-de-dados>
/// server db     verify|cat|export <pasta-de-dados> [--key-file <arquivo>]
/// ```
///
/// `serve` sobe a API. `enroll` emite o código que cadastra um aparelho novo
/// — só por aqui, dentro da VM (ADR-008). `db` é o `dbtool` da ADR-005: a
/// resposta ao "ler por SSH" num registro cifrado, **só de leitura**.
Future<void> main(List<String> arguments) async {
  if (arguments.length < 2) {
    stderr.writeln(
      'uso: server serve|enroll|db <pasta-de-dados> [--key-file f]',
    );
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
      await _serve(
        data,
        _keyFile(arguments),
        accessKeyFile: _flag(arguments, '--access-key-file'),
      );
    case 'db':
      // O `dbtool` da ADR-005 existia no pacote e **nunca tinha sido ligado
      // a um executável**: a ferramenta que a ADR promete para ler o
      // registro cifrado não era alcançável por ninguém.
      exitCode = await DbTool(stdout).run(arguments.skip(1).toList());
    default:
      exitCode = 64;
  }
}

/// A chave vem da credencial do systemd; `--key-file` existe para rodar fora
/// de um serviço, em desenvolvimento.
String _keyFile(List<String> arguments) {
  final path =
      _flag(arguments, '--key-file') ??
      DataKey.systemdCredentialPath(Platform.environment);
  if (path == null) {
    throw StateError('Sem chave de dados: use --key-file ou uma credencial.');
  }
  return path;
}

/// O valor que segue a opção [name], ou `null` quando ela não veio.
String? _flag(List<String> arguments, String name) {
  final at = arguments.indexOf(name);
  return at >= 0 && at + 1 < arguments.length ? arguments[at + 1] : null;
}

/// As duas peças que falam com a IA: o classificador de comprovantes e o
/// assistente.
typedef _Ai = ({ReceiptClassifier classifier, AssistantService? assistant});

/// Com a credencial da DeepSeek, a IA entra por cima das regras locais e o
/// assistente responde; sem ela, o servidor sobe só com as regras, o
/// assistente diz que está fora do ar, e tudo o mais continua funcionando.
///
/// O orçamento de tokens e o disjuntor são **um só** para as duas peças
/// (RN-960): conversa e classificação gastam do mesmo teto.
_Ai _ai(EventStore store) {
  final directory = Platform.environment['CREDENTIALS_DIRECTORY'];
  final keyFile = directory == null
      ? null
      : File(p.join(directory, DeepSeekChatClient.credentialName));
  if (keyFile == null || !keyFile.existsSync()) {
    stdout.writeln(
      'sem credencial da IA: classificando só pelas regras locais',
    );
    return (classifier: const RuleBasedClassifier(), assistant: null);
  }
  final client = DeepSeekChatClient(apiKey: keyFile.readAsStringSync().trim());
  final budget = TokenBudget(store, monthlyLimit: 2000000);
  final breaker = CircuitBreaker();
  return (
    classifier: AiReceiptClassifier(
      client: client,
      budget: budget,
      breaker: breaker,
    ),
    assistant: AssistantService(
      client: client,
      budget: budget,
      breaker: breaker,
    ),
  );
}

/// O servidor montado sobre o registro [store]: a IA se houver credencial,
/// a chave da casa (ADR-020) se houver credencial — sem ela, só a
/// autenticação antiga vale —, e a origem da web.
App _app(EventStore store, Directory data, {String? accessKeyFile}) {
  final ai = _ai(store);
  return App(
    store: store,
    dataDirectory: data,
    clock: const SystemClock(),
    log: stdout.writeln,
    sessions: SessionBook(),
    classifier: ai.classifier,
    assistant: ai.assistant,
    householdKey: HouseholdKey.load(
      environment: Platform.environment,
      file: accessKeyFile,
    ),
    // Um ensaio em outra Vercel troca a origem sem recompilar.
    webOrigin: Platform.environment['WEB_ORIGIN'] ?? App.defaultWebOrigin,
  );
}

Future<void> _serve(
  Directory data,
  String keyFile, {
  String? accessKeyFile,
}) async {
  final store = await FileEventStore.open(
    data,
    AesGcmRecordCipher(DataKey.read(keyFile)),
  );
  final app = _app(store, data, accessKeyFile: accessKeyFile);
  // Só na própria máquina: quem recebe a internet é o Caddy (ADR-003 · T-36).
  final host = Platform.environment['HOST'] ?? '127.0.0.1';
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await io.serve(app.handler, InternetAddress(host), port);
  stdout.writeln('ouvindo em http://${server.address.host}:${server.port}');
}
