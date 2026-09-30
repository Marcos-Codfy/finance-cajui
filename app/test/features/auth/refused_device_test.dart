import 'dart:typed_data';

import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/auth/application/device_key_store.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_server.dart';

/// Uma chave com a janela do dia aberta ou fechada, à escolha do teste. É
/// o caso do celular de verdade: desbloquear a tela já abre a janela, e a
/// chave assina sem perguntar nada.
final class _Keys implements DeviceKeyStore {
  new({this.unlocked = true});

  /// Se a liberação do dia ainda vale.
  final bool unlocked;

  @override
  bool get exists => true;

  @override
  Future<bool> canAuthenticate() async => true;

  @override
  Future<Uint8List> publicKey() async => Uint8List.fromList([1, 2, 3, 4]);

  @override
  Future<Uint8List> sign(Uint8List message) async => message;

  @override
  Future<Uint8List> signQuietly(Uint8List message) async =>
      unlocked ? message : Uint8List(0);
}

void main() {
  late FakeServer server;

  CajuiApi apiWith(_Keys keys) =>
      CajuiApi(baseUrl: server.baseUrl, keys: keys, client: server.client);

  setUp(() async {
    server = await FakeServer.start();
    addTearDown(server.stop);
  });

  group('ADR-008 · o aparelho que o servidor não conhece', () {
    test('recusado uma vez, não insiste em silêncio: o que falta é o '
        'cadastro', () async {
      final api = apiWith(_Keys());
      server.refuseWith(ErrorCode.auth03);

      expect(await api.openQuietly(), isFalse);
      expect(api.isRefused, isTrue);
      final asked = server.paths.length;

      expect(await api.openQuietly(), isFalse);
      expect(server.paths, hasLength(asked), reason: 'não perguntou de novo');
    });

    test('cadastrado, volta a abrir a sessão sozinho', () async {
      final api = apiWith(_Keys());
      server.refuseOnceWith(ErrorCode.auth03);
      await api.openQuietly();
      expect(api.isRefused, isTrue);

      expect(await api.enroll('ABC123XYZ0', name: 'Celular'), isNull);

      expect(api.isRefused, isFalse);
      expect(await api.openQuietly(), isTrue);
    });

    test('código recusado não apaga a recusa: o aparelho continua sem '
        'cadastro', () async {
      final api = apiWith(_Keys());
      server.refuseWith(ErrorCode.auth03);
      await api.openQuietly();
      server.refuseWith(ErrorCode.auth04);

      expect(await api.enroll('errado', name: 'Celular'), ErrorCode.auth04);

      expect(api.isRefused, isTrue);
    });

    test('o envio pedido pela pessoa tenta de novo, e o aceite desfaz a '
        'recusa', () async {
      final api = apiWith(_Keys());
      server.refuseOnceWith(ErrorCode.auth03);
      await api.openQuietly();

      final (_, failure) = await api.devices();

      expect(failure, isNull);
      expect(api.isRefused, isFalse);
    });

    test('janela do dia fechada não é recusa do servidor', () async {
      final api = apiWith(_Keys(unlocked: false));

      expect(await api.openQuietly(), isFalse);

      expect(api.isRefused, isFalse);
      expect(server.paths, isEmpty);
    });

    test('sem rede não é recusa do servidor', () async {
      final api = apiWith(_Keys());
      await server.stop();

      expect(await api.openQuietly(), isFalse);

      expect(api.isRefused, isFalse);
    });
  });
}
