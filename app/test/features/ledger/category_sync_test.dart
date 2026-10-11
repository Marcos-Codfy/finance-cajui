import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/ledger/application/catalog_stamp.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_sync.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_uplink.dart';

/// O que o servidor tem de cada categoria do cadastro de fábrica, como um
/// servidor de antes da ADR-024 guardou: igual ao daqui, sem carimbo.
void _serverHasTheFactoryCatalog(FakeUplink uplink) {
  for (final category in DefaultCatalog.categories) {
    uplink.categories.add(category.id);
    uplink.catalog['category:${category.id}'] = CategoryCodec.encode(category);
  }
}

void main() {
  late FakeUplink uplink;
  late LedgerSync sync;

  setUp(() {
    uplink = FakeUplink();
    sync = LedgerSync(uplink);
    _serverHasTheFactoryCatalog(uplink);
  });

  /// O que subiu de [id] nesta sincronização, se subiu.
  Map<String, Object?>? sent(String id) => uplink.catalog['category:$id'];

  group('ADR-024 · a categoria reagrupada sobe', () {
    test('categoria igual à do servidor não sobe de novo', () async {
      await sync.run(DefaultCatalog.emptyBook);

      expect(sent('groceries'), isNot(contains('definedAt')));
    });

    test('a que o servidor tem em outro grupo — de uma versão velha do app '
        '— sobe com o carimbo do cadastro daqui', () async {
      uplink.catalog['category:interest-and-fees'] = {
        ...CategoryCodec.encode(
          DefaultCatalog.emptyBook.categoryOf('interest-and-fees'),
        ),
        'block': Block.variable.name,
        'groupId': 'other',
      };

      await sync.run(DefaultCatalog.emptyBook);

      final fees = sent('interest-and-fees')!;
      expect(fees['block'], Block.debt.name);
      expect(fees['groupId'], 'debt');
      expect(
        CatalogVersion.definedAtOf(fees),
        CatalogStamp.definedAt,
        reason: 'o carimbo é o da última mudança do cadastro de fábrica',
      );
    });

    test('a que o servidor tem mais nova — de um app mais novo, no outro '
        'celular — não é desfeita por este', () async {
      final newer = {
        ...CategoryCodec.encode(DefaultCatalog.emptyBook.categoryOf('home')),
        'groupId': 'household',
        'definedAt': '2099-01-01T00:00:00.000Z',
      };
      uplink.catalog['category:home'] = newer;

      await sync.run(DefaultCatalog.emptyBook);

      expect(sent('home'), newer);
    });
  });
}
