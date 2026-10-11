import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

/// O cadastro que atravessa de um celular para o outro (ADR-024): cartão
/// editado e categoria reagrupada sobem e descem, e vale a versão mais nova.
void main() {
  final card = CreditCard.create(
    id: 'card-1',
    name: 'Cartão da casa',
    closingDay: 25,
    dueDay: 5,
    creditLimit: const Money.fromCents(500000),
  ).valueOrNull!;
  final monday = DateTime.utc(2026, 10, 5, 9);
  final friday = DateTime.utc(2026, 10, 9, 18);

  Map<String, Object?> cardWith({int closingDay = 25, DateTime? at}) =>
      CatalogVersion.stamped({
        ...CardCodec.encodeCard(card),
        'closingDay': closingDay,
      }, at);

  group('ADR-024 · a versão de um item do cadastro', () {
    test('o carimbo vai junto do conteúdo, em UTC, e volta igual', () {
      final payload = cardWith(at: DateTime.utc(2026, 10, 9, 18, 30));

      expect(payload['definedAt'], '2026-10-09T18:30:00.000Z');
      expect(
        CatalogVersion.definedAtOf(payload),
        DateTime.utc(2026, 10, 9, 18, 30),
      );
      expect(CatalogVersion.stamped(cardWith(), null), cardWith());
    });

    test('a assinatura é o conteúdo: o carimbo e o id não mudam ela, e o '
        'dia de fechamento muda', () {
      final base = CatalogVersion.of(cardWith(at: monday));

      expect(CatalogVersion.of(cardWith(at: friday)).signature, base.signature);
      expect(
        CatalogVersion.of({...cardWith(), 'id': 'outro'}).signature,
        base.signature,
      );
      expect(
        CatalogVersion.of(cardWith(closingDay: 28)).signature,
        isNot(base.signature),
      );
    });

    test('guardado: a versão mais nova toma o lugar; a mais velha não', () {
      final old = CatalogVersion.of(cardWith(at: monday));
      final edited = CatalogVersion.of(cardWith(closingDay: 28, at: friday));

      expect(edited.replaces(old), isTrue);
      expect(old.replaces(edited), isFalse);
      expect(edited.replaces(null), isTrue, reason: 'item novo entra');
      expect(
        CatalogVersion.of(cardWith(at: friday)).replaces(old),
        isFalse,
        reason: 'mesmo conteúdo não é versão nova',
      );
    });

    test('versão sem carimbo, gravada antes dele existir, é a mais velha', () {
      final legacy = CatalogVersion.of(cardWith(closingDay: 20));
      final stamped = CatalogVersion.of(cardWith(at: monday));

      expect(stamped.replaces(legacy), isTrue);
      expect(legacy.replaces(stamped), isFalse);
      expect(
        CatalogVersion.of(cardWith()).replaces(legacy),
        isTrue,
        reason: 'entre duas sem carimbo vale a que chega, como antes',
      );
    });

    test('subir: só a versão daqui estritamente mais nova passa por cima', () {
      final remote = CatalogVersion.of(cardWith(at: monday));

      expect(
        CatalogVersion.of(cardWith(closingDay: 28, at: friday))
            .overrides(remote),
        isTrue,
      );
      expect(
        CatalogVersion.of(cardWith(closingDay: 28)).overrides(remote),
        isFalse,
        reason: 'sem carimbo nunca sobe por cima',
      );
      expect(
        CatalogVersion.of(cardWith(at: friday)).overrides(remote),
        isFalse,
      );
      expect(CatalogVersion.of(cardWith()).overrides(null), isTrue);
    });
  });

  group('CategoryCodec', () {
    test('a categoria vai e volta inteira, bloco e vale inclusive', () {
      const fees = Category(
        id: 'interest-and-fees',
        name: 'Juros e tarifas',
        block: Block.debt,
        groupId: 'debt',
      );

      final back = CategoryCodec.decode(CategoryCodec.encode(fees));

      expect(back.id, 'interest-and-fees');
      expect(back.block, Block.debt);
      expect(back.groupId, 'debt');
      expect(back.voucherEligible, isFalse);
    });

    test('bloco desconhecido é pedido malformado', () {
      expect(
        () => CategoryCodec.decode({
          'id': 'x',
          'name': 'X',
          'block': 'investimento',
          'groupId': 'x',
        }),
        throwsFormatException,
      );
    });
  });
}
