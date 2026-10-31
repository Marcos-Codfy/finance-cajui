import 'package:cajui/src/core/navigation/navigation_providers.dart';
import 'package:cajui/src/features/budget/presentation/amount_page.dart';
import 'package:cajui/src/features/budget/presentation/budget_coordinator.dart';
import 'package:cajui/src/features/budget/presentation/month_page.dart';
import 'package:cajui/src/features/cards/presentation/cards_coordinator.dart';
import 'package:cajui/src/features/cards/presentation/cards_page.dart';
import 'package:cajui/src/features/debts/presentation/debt_detail_page.dart';
import 'package:cajui/src/features/debts/presentation/debts_coordinator.dart';
import 'package:cajui/src/features/ledger/presentation/entry_detail_page.dart';
import 'package:cajui/src/features/ledger/presentation/entry_form_page.dart';
import 'package:cajui/src/features/ledger/presentation/ledger_coordinator.dart';
import 'package:cajui/src/features/ledger/presentation/option_picker_page.dart';
import 'package:cajui/src/features/settings/presentation/settings_coordinator.dart';
import 'package:cajui/src/features/settings/presentation/settings_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/recording_scene_navigator.dart';

ProviderContainer _with(RecordingSceneNavigator navigator) {
  final container = ProviderContainer(
    overrides: [sceneNavigatorProvider.overrideWithValue(navigator)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('ADR-031 · o coordinator decide para onde ir, sem desenhar tela', () {
    test(
      'o Início abre o Meu mês, os cartões e os ajustes pelo coordinator',
      () async {
        final navigator = RecordingSceneNavigator();
        final container = _with(navigator);

        await container.read(budgetCoordinatorProvider).openMonth();
        await container.read(cardsCoordinatorProvider).openCards();
        await container.read(settingsCoordinatorProvider).openSettings();

        expect(navigator.pushed, [
          isA<MonthPage>(),
          isA<CardsPage>(),
          isA<SettingsPage>(),
        ]);
      },
    );

    test('o detalhe do lançamento e da dívida levam o identificador', () async {
      final navigator = RecordingSceneNavigator();
      final container = _with(navigator);

      await container.read(ledgerCoordinatorProvider).openEntry('e-0001');
      await container.read(debtsCoordinatorProvider).openDebt('d-0001');

      expect(navigator.pushed, [
        isA<EntryDetailPage>().having((p) => p.entryId, 'entryId', 'e-0001'),
        isA<DebtDetailPage>().having((p) => p.debtId, 'debtId', 'd-0001'),
      ]);
    });

    test(
      'lançar à mão abre o formulário, e fechar devolve o resultado',
      () async {
        final navigator = RecordingSceneNavigator();
        final ledger = _with(navigator).read(ledgerCoordinatorProvider);

        await ledger.openEntryForm();
        ledger.close(42);

        expect(navigator.pushed.single, isA<EntryFormPage>());
        expect(navigator.popped, [42]);
      },
    );

    test(
      'a escolha curta sobe como painel, e devolve o que foi escolhido',
      () async {
        final navigator = RecordingSceneNavigator(answer: 'Mercado');
        final ledger = _with(navigator).read(ledgerCoordinatorProvider);

        final picked = await ledger.pick<String>(
          title: 'Categoria',
          options: const ['Mercado', 'Lazer'],
          labelOf: (option) => option,
        );

        expect(picked, 'Mercado');
        expect(navigator.sheets.single, isA<OptionPickerPage<String>>());
        expect(navigator.pushed, isEmpty);
      },
    );

    test('pedir um valor abre a tela de valor e devolve os centavos', () async {
      final navigator = RecordingSceneNavigator(answer: 4590);
      final budget = _with(navigator).read(budgetCoordinatorProvider);

      final cents = await budget.askAmount(
        title: 'Limite',
        label: 'Quanto',
        explanation: 'Explica o valor.',
      );

      expect(cents, 4590);
      expect(navigator.pushed.single, isA<AmountPage>());
    });

    test('quem desiste da escolha recebe nulo, e não uma exceção', () async {
      final navigator = RecordingSceneNavigator();
      final ledger = _with(navigator).read(ledgerCoordinatorProvider);

      final picked = await ledger.pick<int>(
        title: 'Dia',
        options: const [1, 2],
        labelOf: (option) => '$option',
      );

      expect(picked, isNull);
    });
  });
}
