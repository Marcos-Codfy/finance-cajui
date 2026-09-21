import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Roda também no navegador — `flutter test --platform chrome` — porque foi
/// lá que o gerador quebrou: inteiro na web é o do JavaScript, e a conta que
/// funcionava no Android lançava erro.
void main() {
  test('o gerador de identificador de verdade não repete e cabe no limite '
      'do contrato', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final newId = container.read(newIdProvider);

    final ids = {for (var i = 0; i < 200; i++) newId()};

    expect(ids, hasLength(200));
    for (final id in ids) {
      expect(id, matches(RegExp(r'^[0-9a-z]+-[0-9a-f]{8}$')));
      expect(id.length, lessThanOrEqualTo(64));
    }
  });
}
