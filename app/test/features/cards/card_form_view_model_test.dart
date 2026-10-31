import 'package:cajui/src/features/cards/presentation/card_form_state.dart';
import 'package:cajui/src/features/cards/presentation/card_form_view_model.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_scope.dart';

CardDraft _draft({
  int closingDay = 5,
  int dueDay = 12,
  String name = 'Roxinho',
}) => (
  id: null,
  name: name,
  closingDay: closingDay,
  dueDay: dueDay,
  creditLimit: null,
  skin: null,
);

void main() {
  late ProviderContainer container;

  CardFormViewModel form() => container.read(cardFormProvider.notifier);
  CardFormState state() => container.read(cardFormProvider);
  Future<List<CreditCard>> cards() async =>
      (await container.read(ledgerProvider.future)).cards;

  setUp(() {
    container = ProviderContainer(overrides: testOverrides());
    addTearDown(container.dispose);
    // Mantém o ViewModel vivo: ele é descartado quando ninguém o escuta.
    container.listen(cardFormProvider, (_, _) {});
  });

  test('RN-302 · nasce sem recusa nenhuma', () {
    expect(state(), isA<CardFormEditing>());
    expect((state() as CardFormEditing).dayProblem, isNull);
  });

  test('RN-302 · o cartão válido é gravado, e a tela pode fechar', () async {
    await form().save(_draft());

    expect(state(), isA<CardFormSaved>());
    expect((await cards()).map((card) => card.name), ['Roxinho']);
  });

  test('E-CARD-01 · dia que não existe volta como frase do catálogo, e nada '
      'é gravado', () async {
    await form().save(_draft(closingDay: 40));

    final editing = state() as CardFormEditing;
    expect(editing.dayProblem, isNotNull);
    expect(editing.dayProblem, isNotEmpty);
    expect(await cards(), isEmpty);
  });

  test('o segundo toque em "Guardar" antes de gravar não cadastra outro '
      'cartão', () async {
    final first = form().save(_draft());
    final second = form().save(_draft());
    await Future.wait([first, second]);

    expect(await cards(), hasLength(1));
  });

  test(
    'depois de uma recusa, corrigir o dia e guardar de novo funciona',
    () async {
      await form().save(_draft(closingDay: 40));
      await form().save(_draft());

      expect(state(), isA<CardFormSaved>());
      expect(await cards(), hasLength(1));
    },
  );
}
