import 'dart:convert';
import 'dart:typed_data';

import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/assistant/application/assistant_reply.dart';
import 'package:cajui/src/features/assistant/infrastructure/http_assistant_gateway.dart';
import 'package:cajui/src/features/assistant/presentation/assistant_reply_view.dart';
import 'package:cajui/src/features/auth/application/device_key_failure.dart';
import 'package:cajui/src/features/auth/application/device_key_store.dart';
import 'package:cajui/src/features/auth/application/server_session.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_server.dart';

/// Uma chave de aparelho de mentira: assina devolvendo a própria mensagem.
/// Basta para o teste — quem confere assinatura é o servidor, que aqui é o
/// dublê.
final class _FakeKeys implements DeviceKeyStore {
  int signatures = 0;

  @override
  bool get exists => true;

  @override
  Future<bool> canAuthenticate() async => true;

  @override
  Future<Uint8List> publicKey() async => Uint8List.fromList([1, 2, 3, 4]);

  @override
  Future<Uint8List> sign(Uint8List message) async {
    signatures++;
    return message;
  }
}

/// Uma chave que recusa: é o Keystore dizendo não, como no aparelho.
final class _RefusingKeys implements DeviceKeyStore {
  @override
  bool get exists => true;

  @override
  Future<bool> canAuthenticate() async => true;

  @override
  Future<Uint8List> publicKey() async => Uint8List.fromList([1, 2, 3, 4]);

  @override
  Future<Uint8List> sign(Uint8List message) async =>
      throw const DeviceKeyFailure(ErrorCode.auth01);
}

void main() {
  late FakeServer server;
  late _FakeKeys keys;
  late CajuiApi api;

  setUp(() async {
    server = await FakeServer.start();
    keys = _FakeKeys();
    api = CajuiApi(baseUrl: server.baseUrl, keys: keys, client: server.client);
    addTearDown(server.stop);
  });

  group('cadastro do aparelho (ADR-008)', () {
    test('o identificador vem da chave pública, e não de sorteio', () {
      final first = deviceIdOf([1, 2, 3, 4]);

      expect(first, deviceIdOf([1, 2, 3, 4]));
      expect(first, isNot(deviceIdOf([9, 9, 9, 9])));
      expect(first, hasLength(32));
    });

    test('cadastrar manda o código e a chave pública, e nada mais', () async {
      final failure = await api.enroll('ABC123XYZ0', name: 'Celular');

      expect(failure, isNull);
      final sent = server.requests.single;
      expect(sent.path, '/v1/auth/enroll');
      expect(sent.body.keys.toSet(), {'code', 'deviceId', 'name', 'publicKey'});
      expect(sent.body['publicKey'], base64Encode([1, 2, 3, 4]));
    });

    test(
      'E-AUTH-04 · código vencido, usado ou errado volta do catálogo',
      () async {
        server.refuseWith(ErrorCode.auth04);

        expect(await api.enroll('errado', name: 'Celular'), ErrorCode.auth04);
      },
    );
  });

  group('sessão', () {
    test(
      'a sessão nasce de desafio assinado, e é reusada enquanto vale',
      () async {
        final gateway = HttpAssistantGateway(api);

        await gateway.ask('quanto gastei?');
        await gateway.ask('e na semana?');

        // Um desafio só: a segunda pergunta reusou a sessão aberta.
        expect(keys.signatures, 1);
        expect(
          server.paths.where((p) => p.endsWith('/challenge')),
          hasLength(1),
        );
        expect(server.paths.last, '/v1/assistant/ask');
        expect(api.isOpen, isTrue);
      },
    );

    test('sessão recusada no meio faz um desafio novo, uma vez só', () async {
      final gateway = HttpAssistantGateway(api);
      await gateway.ask('primeira');
      server.refuseOnceWith(ErrorCode.auth03);

      await gateway.ask('segunda');

      expect(keys.signatures, 2);
    });

    test('a pergunta sobe sozinha: nenhum número vai junto (RN-915)', () async {
      await HttpAssistantGateway(api).ask('quanto sobrou?');

      final ask = server.requests.last;
      expect(ask.body.keys.toSet(), {'message'});
      expect(ask.body['message'], 'quanto sobrou?');
      expect(ask.authorization, startsWith('Bearer '));
    });

    test(
      'aparelho que o servidor não conhece pede cadastro, e não erro seco',
      () async {
        // Este é o caminho do primeiro uso no aparelho: a digital confirma,
        // a assinatura sobe, e o servidor responde que não conhece quem
        // assinou. O código tem de atravessar inteiro — o corpo de erro
        // traz `code` **dentro de `error`**, e lê-lo na raiz transformava
        // esta recusa numa falha sem nome.
        server.refuseWith(ErrorCode.auth03);

        final reply = await HttpAssistantGateway(api).ask('oi');

        expect(reply, isA<AssistantNotPaired>());
      },
    );

    test(
      'Keystore que recusa vira erro na tela, e não conversa travada',
      () async {
        // O primeiro uso no aparelho travou aqui: a recusa do Keystore subia
        // como exceção de plataforma, ninguém a pegava, e a conversa ficava
        // em "pensando" para sempre.
        final api = CajuiApi(
          baseUrl: server.baseUrl,
          keys: _RefusingKeys(),
          client: server.client,
        );

        final reply = await HttpAssistantGateway(api).ask('oi');

        expect((reply as AssistantFailed).code, ErrorCode.auth01);
      },
    );

    test(
      'BL-047 · o nome do aparelho vai no cadastro, e não um fixo',
      () async {
        await api.enroll('codigo-de-teste', name: 'S22 do Marcos');

        final pedido = server.requests.firstWhere(
          (r) => r.path == '/v1/auth/enroll',
        );

        expect(pedido.body['name'], 'S22 do Marcos');
      },
    );

    test('BL-048 · o tempo de espera vem do servidor, e não de um número '
        'inventado na tela', () async {
      server.refuseWith(ErrorCode.ai02, status: 503, retryAfterSeconds: 25);

      final reply = await HttpAssistantGateway(api).ask('oi');
      final texto = AssistantReplyView.textOf(
        (reply as AssistantFailed).code,
        retryAfterSeconds: reply.retryAfterSeconds,
      );

      expect(reply.retryAfterSeconds, 25);
      expect(texto.message, contains('25'));
      expect(texto.message, isNot(contains('60')));
    });

    test('sem servidor, a conversa falha com E-NET-01', () async {
      await server.stop();

      final reply = await HttpAssistantGateway(api).ask('oi');

      expect((reply as AssistantFailed).code, ErrorCode.net01);
    });
  });

  test('a resposta chega inteira, com as origens dos números', () async {
    server.answer = {
      'text': r'Você gastou R$ 120,00 em mercado.',
      'outOfScope': false,
      'fallback': false,
      'sources': [
        {
          'label': 'Mercado em setembro',
          'cents': 12000,
          'kind': 'spent',
          'period': '2026-09',
        },
      ],
    };

    final reply = await HttpAssistantGateway(api)
        .ask('quanto gastei em mercado?');

    final answered = reply as AssistantAnswered;
    expect(answered.text, r'Você gastou R$ 120,00 em mercado.');
    expect(answered.sources.single.label, 'Mercado em setembro');
    expect(answered.sources.single.cents, 12000);
  });
}
