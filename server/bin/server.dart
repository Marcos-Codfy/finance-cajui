import 'dart:io';

import 'package:domain/domain.dart';
import 'package:path/path.dart' as p;
import 'package:persistence/persistence.dart';
import 'package:server/src/ai/ai_receipt_classifier.dart';
import 'package:server/src/ai/ai_statement_reader.dart';
import 'package:server/src/ai/chat_client.dart';
import 'package:server/src/ai/circuit_breaker.dart';
import 'package:server/src/ai/claude_chat_client.dart';
import 'package:server/src/ai/deepseek_chat_client.dart';
import 'package:server/src/ai/token_budget.dart';
import 'package:server/src/app.dart';
import 'package:server/src/assistant/assistant_service.dart';
import 'package:server/src/auth/household_key.dart';
import 'package:server/src/auth/session_book.dart';
import 'package:server/src/auth/totp.dart';
import 'package:server/src/system_clock.dart';
import 'package:shelf/shelf_io.dart' as io;

/// O servidor do Cajui.
///
/// ```text
/// server serve  <pasta-de-dados> [--key-file <arquivo>] [--access-key-file <arquivo>]
/// server db     verify|cat|export <pasta-de-dados> [--key-file <arquivo>]
/// ```
///
/// `serve` sobe a API. `db` é o `dbtool` da ADR-005: a resposta ao "ler por
/// SSH" num registro cifrado, **só de leitura**. O `enroll`, que emitia o
/// código de cadastro de aparelho, saiu com a ADR-024: quem entra é quem
/// tem a chave da casa.
Future<void> main(List<String> arguments) async {
  if (arguments.length < 2) {
    stderr.writeln('uso: server serve|db <pasta-de-dados> [--key-file f]');
    exitCode = 64;
    return;
  }
  final data = Directory(arguments[1]);
  switch (arguments.first) {
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

/// As peças que falam com a IA: o classificador de comprovantes, o
/// assistente e o leitor de extrato.
typedef _Ai = ({
  ReceiptClassifier classifier,
  AssistantService? assistant,
  AiStatementReader? statements,
});

/// Com a credencial da DeepSeek, a IA entra por cima das regras locais e o
/// assistente responde; sem ela, o servidor sobe só com as regras, o
/// assistente diz que está fora do ar, e tudo o mais continua funcionando.
///
/// O orçamento de tokens e o disjuntor são **um só** para as três peças
/// (RN-960): conversa, classificação e extrato gastam do mesmo teto.
_Ai _ai(EventStore store) {
  final client = _client(Platform.environment['CREDENTIALS_DIRECTORY']);
  if (client == null) {
    stdout.writeln(
      'sem credencial da IA: classificando só pelas regras locais',
    );
    return (
      classifier: const RuleBasedClassifier(),
      assistant: null,
      statements: null,
    );
  }
  return _pieces(
    client,
    TokenBudget(store, monthlyLimit: 2000000),
    CircuitBreaker(),
  );
}

/// Quem fala com a IA. Com a credencial do Claude instalada, ele (o dono
/// usou por um dia em 18/10/2026); senão a DeepSeek, como sempre. Voltar à
/// DeepSeek é tirar a credencial do Claude — o resto não muda.
ChatClient? _client(String? directory) {
  if (directory == null) return null;
  String? key(String name) {
    final file = File(p.join(directory, name));
    return file.existsSync() ? file.readAsStringSync().trim() : null;
  }

  if (key(ClaudeChatClient.credentialName) case final claude?) {
    stdout.writeln('IA: Claude (${ClaudeChatClient.model})');
    return ClaudeChatClient(apiKey: claude);
  }
  if (key(DeepSeekChatClient.credentialName) case final deepSeek?) {
    return DeepSeekChatClient(apiKey: deepSeek);
  }
  return null;
}

/// As três peças sobre o mesmo [client], o mesmo [budget] e o mesmo
/// [breaker].
_Ai _pieces(ChatClient client, TokenBudget budget, CircuitBreaker breaker) => (
  classifier: AiReceiptClassifier(
    client: client,
    budget: budget,
    breaker: breaker,
  ),
  assistant: AssistantService(client: client, budget: budget, breaker: breaker),
  statements: AiStatementReader(
    client: client,
    budget: budget,
    breaker: breaker,
  ),
);

/// O servidor montado sobre o registro [store]: a IA se houver credencial,
/// a chave da casa (ADR-020) e a origem da web. Sem a chave o servidor
/// sobe, responde se está de pé e não deixa ninguém entrar — e diz isso
/// no registro do serviço, que é onde quem fez o deploy vai olhar.
App _app(EventStore store, {String? accessKeyFile}) {
  final ai = _ai(store);
  final key = HouseholdKey.load(
    environment: Platform.environment,
    file: accessKeyFile,
  );
  if (key == null) stdout.writeln('sem chave da casa: ninguém vai entrar');
  final totp = Totp.load(environment: Platform.environment);
  if (totp == null) {
    stdout.writeln('sem segredo do autenticador: a web entra só com a chave');
  }
  return App(
    store: store,
    clock: const SystemClock(),
    log: stdout.writeln,
    sessions: SessionBook(),
    classifier: ai.classifier,
    assistant: ai.assistant,
    statementReader: ai.statements,
    householdKey: key,
    totp: totp,
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
  final app = _app(store, accessKeyFile: accessKeyFile);
  // Só na própria máquina: quem recebe a internet é o Caddy (ADR-003 · T-36).
  final host = Platform.environment['HOST'] ?? '127.0.0.1';
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await io.serve(app.handler, InternetAddress(host), port);
  stdout.writeln('ouvindo em http://${server.address.host}:${server.port}');
}
