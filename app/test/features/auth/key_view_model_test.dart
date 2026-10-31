import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/auth/application/code_exchange.dart';
import 'package:cajui/src/features/auth/presentation/key_state.dart';
import 'package:cajui/src/features/auth/presentation/key_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_household_key.dart';
import '../../support/test_scope.dart';

/// O servidor de mentira: só o código [valid] abre sessão.
final class _Exchange implements CodeExchange {
  new(this.valid);

  final String valid;
  final tried = <String>[];

  @override
  Future<CodeOutcome> tokenFor(String code) async {
    tried.add(code);
    return code == valid
        ? (token: 'token-de-teste', error: null, retryAfterSeconds: null)
        : (token: null, error: ErrorCode.auth04, retryAfterSeconds: null);
  }
}

const _longKey = 'chave-da-casa-de-teste-com-tamanho-bom';

void main() {
  late ProviderContainer container;
  late FakeHouseholdKey keys;
  late _Exchange exchange;

  KeyViewModel form() => container.read(keyProvider.notifier);
  KeyState state() => container.read(keyProvider);

  setUp(() {
    keys = FakeHouseholdKey(null);
    exchange = _Exchange('123456');
    container = ProviderContainer(
      overrides: [
        ...testOverrides(householdKey: keys),
        codeExchangeProvider.overrideWithValue(exchange),
      ],
    );
    addTearDown(container.dispose);
    container.listen(keyProvider, (_, _) {});
  });

  group('ADR-027 · o que foi digitado é código ou chave', () {
    test('seis dígitos, com ou sem espaço, são o código', () {
      expect(KeyViewModel.isCode('123456'), isTrue);
      expect(KeyViewModel.isCode(' 123 456 '), isTrue);
      expect(KeyViewModel.digitsOf(' 123 456 '), '123456');
    });

    test('cinco dígitos nem são código nem uma chave do tamanho da chave', () {
      expect(KeyViewModel.isCode('12345'), isFalse);
      expect(KeyViewModel.isReady('12345'), isFalse);
    });

    test('a chave só serve a partir do tamanho da chave', () {
      expect(KeyViewModel.isReady('curta'), isFalse);
      expect(KeyViewModel.isReady(_longKey), isTrue);
    });
  });

  group('ADR-020 · entrar na consulta', () {
    test('o código certo vira sessão, e a chave fica guardada', () async {
      await form().enter('123 456');

      expect(state(), isA<KeyEntered>());
      expect(exchange.tried, ['123456']);
      expect(keys.key, 'token-de-teste');
    });

    test('E-AUTH-04 · o código errado volta como frase do catálogo, e '
        'nada é guardado', () async {
      await form().enter('000000');

      final editing = state() as KeyEditing;
      expect(editing.problem?.code, ErrorCode.auth04);
      expect(keys.key, isNull);
    });

    test(
      'a chave da casa digitada é guardada sem passar pelo servidor',
      () async {
        await form().enter(_longKey);

        expect(state(), isA<KeyEntered>());
        expect(exchange.tried, isEmpty);
        expect(keys.key, _longKey);
      },
    );

    test('o que ainda não dá para mandar é ignorado', () async {
      await form().enter('12345');

      expect(state(), isA<KeyEditing>());
      expect(exchange.tried, isEmpty);
    });

    test('dispensar o aviso volta a digitar sem recusa', () async {
      await form().enter('000000');

      form().dismissProblem();

      expect((state() as KeyEditing).problem, isNull);
    });
  });
}
