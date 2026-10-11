import 'package:domain/domain.dart';
import 'package:test/test.dart';

/// Os nomes da casa e a regra de quando o nome que o banco escreveu é um
/// deles. Todos os nomes são inventados.
void main() {
  const marcos = 'Marcos Vinícius Muniz Arruda';
  final cadastro = PersonName.of(marcos);
  final at = DateTime.utc(2026, 10, 11, 12);

  group('RN-1071 · o nome que o banco escreveu é da casa', () {
    for (final written in [
      'MARCOS V M ARRUDA',
      'MARCOS VINICIUS MUNIZ A',
      'Marcos Arruda',
      'MARCOS VINICIUS MUNIZ ARRU',
      'marcos vinicius muniz arruda',
      'MARCOS DE ARRUDA',
    ]) {
      test('"$written" casa com "$marcos"', () {
        expect(cadastro.isWrittenAs(PersonName.of(written)), isTrue);
      });
    }

    for (final written in [
      'MARCOS A',
      'MARCOS SILVA',
      'MARCOS ANTONIO ARRUDA',
      'MARCOS VINICIUS',
      'M VINICIUS ARRUDA',
      'MARCOS',
      'BEATRIZ LIMA',
      'MARCOS ARRUDA SILVA',
    ]) {
      test('"$written" não casa: é outra pessoa, ou não dá para saber', () {
        expect(cadastro.isWrittenAs(PersonName.of(written)), isFalse);
      });
    }

    test('as palavras do meio contam na ordem do cadastro', () {
      expect(cadastro.isWrittenAs(PersonName.of('MARCOS M V ARRUDA')), isFalse);
      expect(cadastro.isWrittenAs(PersonName.of('MARCOS M ARRUDA')), isTrue);
    });

    test('Sá é sobrenome, e não razão social', () {
      final maria = PersonName.of('Maria de Sá');

      expect(maria.isFull, isTrue);
      expect(maria.isWrittenAs(PersonName.of('MARIA SA')), isTrue);
    });

    test('sameAs vale nos dois sentidos: o comprovante abrevia de um jeito e '
        'a notificação de outro', () {
      final full = PersonName.of('JOANA PEREIRA LIMA');
      final short = PersonName.of('Joana P Lima');

      expect(full.sameAs(short), isTrue);
      expect(short.sameAs(full), isTrue);
    });
  });

  group('RN-1070 · a lista de nomes da casa', () {
    test('nome sem sobrenome não entra: casaria com qualquer Marcos', () {
      expect(HouseholdNames.accepts('Marcos'), isFalse);
      expect(HouseholdNames.accepts(marcos), isTrue);
      expect(HouseholdNames.accepts('${'a' * 40} ${'b' * 40}'), isFalse);
    });

    test('incluir, não repetir e tirar, com o carimbo de quando', () {
      final one = HouseholdNames.empty.adding(marcos, at);
      final again = one.adding('MARCOS V M ARRUDA', at);
      final two = one.adding('Beatriz Souza Lima', at);
      final back = two.removing(marcos, at.add(const Duration(minutes: 1)));

      expect(one.names, [marcos]);
      expect(one.definedAt, at);
      expect(again, same(one), reason: 'já é o Marcos da lista');
      expect(two.names, [marcos, 'Beatriz Souza Lima']);
      expect(back.names, ['Beatriz Souza Lima']);
      expect(back.isNewerThan(two), isTrue);
    });

    test('cabem seis nomes', () {
      var names = HouseholdNames.empty;
      for (final first in ['Ana', 'Bia', 'Caio', 'Davi', 'Edu', 'Fabi']) {
        names = names.adding('$first Lima', at);
      }

      expect(names.names, hasLength(HouseholdNames.maxNames));
      expect(names.canAdd('Gabi Lima'), isFalse);
    });

    test('os salários sugerem o primeiro nome: "Salário da Beatriz" sugere '
        'Beatriz, "Meu salário" e "Salário esposa" não sugerem nada', () {
      final names = HouseholdNames.empty.adding(marcos, at);

      expect(
        names.suggestedBy([
          'Salário da Beatriz',
          'Meu salário',
          'Salário esposa',
          'Renda',
          'Marcos',
        ]),
        ['Beatriz'],
      );
    });

    test('quem é da casa, pelo nome que o banco escreveu', () {
      final names = HouseholdNames.empty
          .adding(marcos, at)
          .adding('Beatriz Souza Lima', at);

      expect(names.whoIs('BEATRIZ S LIMA'), 'Beatriz Souza Lima');
      expect(names.whoIs('MARCOS V M ARRUDA'), marcos);
      expect(names.whoIs('MARCOS SILVA'), isNull);
      expect(names.whoIs(null), isNull);
    });
  });

  group('RN-1072 e RN-1073 · dinheiro mudando de conta dentro da casa', () {
    final names = HouseholdNames.empty.adding(marcos, at);
    BankReading reading(MovementKind kind, String? who) => BankReading(
      app: BankApp.nubank,
      kind: kind,
      amount: const Money.fromCents(50000),
      occurredOn: LocalDate(2026, 10, 11),
      counterpart: who,
    );

    test('Pix e transferência, enviados ou recebidos, para alguém da casa', () {
      for (final kind in [
        MovementKind.pixSent,
        MovementKind.pixReceived,
        MovementKind.transferSent,
        MovementKind.transferReceived,
      ]) {
        expect(names.movesWithin(reading(kind, 'MARCOS V M ARRUDA')), isTrue);
      }
    });

    test('compra, boleto, outra pessoa e notificação sem nome não são', () {
      expect(
        names.movesWithin(
          reading(MovementKind.debitPurchase, 'MARCOS V M ARRUDA'),
        ),
        isFalse,
      );
      expect(
        names.movesWithin(reading(MovementKind.boletoPaid, 'MARCOS ARRUDA')),
        isFalse,
      );
      expect(
        names.movesWithin(reading(MovementKind.pixSent, 'MARCOS SILVA')),
        isFalse,
      );
      expect(names.movesWithin(reading(MovementKind.pixSent, null)), isFalse);
      expect(
        HouseholdNames.empty.movesWithin(
          reading(MovementKind.pixSent, 'MARCOS V M ARRUDA'),
        ),
        isFalse,
      );
    });
  });
}
