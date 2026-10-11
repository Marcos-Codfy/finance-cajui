import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/home_navigation.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

/// O espaço que o formatador põe entre `R$` e o número.
const String _nbsp = BrlFormatter.nbsp;

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await _settle(tester);
}

Finder _field(String label) => find.descendant(
  of: find.ancestor(
    of: find.text(label),
    matching: find.byType(CajuiFieldFrame),
  ),
  matching: find.byType(EditableText),
);

/// Abre o app já na tela de dívidas.
Future<MemoryLedgerJournal> _openDebts(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final journal = MemoryLedgerJournal(samplePlanEvents);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(journal: journal),
      child: const CajuiApp(),
    ),
  );
  await tester.pump();
  await openFromHome(tester, 'Dívidas');
  return journal;
}

/// Cadastra um empréstimo de [creditor] em 12 parcelas de R$ 212,00, com
/// [paid] já pagas.
Future<void> _loan(WidgetTester tester, String creditor, {int paid = 0}) async {
  await _tap(tester, find.text('Cadastrar dívida'));
  await tester.enterText(_field('A quem você deve'), creditor);
  await _settle(tester);
  await tester.enterText(_field('Valor da parcela'), '21200');
  await _settle(tester);
  if (paid > 0) {
    await _tap(tester, find.text('Quantas já foram pagas'));
    await _tap(tester, find.text('$paid'));
  }
  await _tap(tester, find.text('Cadastrar'));
}

void main() {
  testWidgets('RN-541 RN-1002 · cadastrar uma dívida: a lista diz quanto '
      'ainda devo e quanto pago por mês, como na planilha', (tester) async {
    final journal = await _openDebts(tester);
    expect(find.text('Nenhuma dívida cadastrada'), findsOneWidget);

    await _loan(tester, 'Empréstimo Banco X', paid: 5);

    expect(find.text('Empréstimo Banco X'), findsOneWidget);
    // Cinco pagas no cadastro e a sexta venceu no dia 10: hoje, 20/09,
    // faltam seis de R$ 212,00 (RN-1030).
    expect(
      find.text(
        '1º · Parcelado · Devo R\$${_nbsp}1.272,00 · '
        'R\$${_nbsp}212,00 por mês',
      ),
      findsOneWidget,
    );
    expect((await journal.readAll()).whereType<DebtDefined>(), hasLength(1));
  });

  testWidgets('RN-1030 · depois de negociar, "Atualizar quanto devo" troca o '
      'saldo da conta atrasada, e o fato novo fica no registro', (
    tester,
  ) async {
    final journal = await _openDebts(tester);
    await _tap(tester, find.text('Cadastrar dívida'));
    await tester.enterText(_field('A quem você deve'), 'Conta de luz');
    await _settle(tester);
    await _tap(tester, find.text('Conta atrasada'));
    await tester.enterText(_field('Quanto ainda devo'), '380000');
    await _settle(tester);
    await tester.enterText(_field('Quanto pago por mês'), '20000');
    await _settle(tester);
    await _tap(tester, find.text('Cadastrar'));

    await _tap(tester, find.text('Conta de luz'));
    await _tap(tester, find.text('Atualizar quanto devo'));
    await tester.enterText(_field('Quanto ainda devo'), '100000');
    await _settle(tester);
    await _tap(tester, find.text('Guardar'));

    expect(find.text('R\$${_nbsp}1.000,00'), findsWidgets);
    expect((await journal.readAll()).whereType<DebtDefined>(), hasLength(2));
  });

  testWidgets('RN-1030 · a parcelada segue o calendário: não há "Atualizar '
      'quanto devo" que a troque por um saldo', (tester) async {
    await _openDebts(tester);
    await _loan(tester, 'Empréstimo Banco X');

    await _tap(tester, find.text('Empréstimo Banco X'));

    expect(find.text('Atualizar quanto devo'), findsNothing);
  });

  testWidgets('RN-1031 · "Quitar esta primeiro" põe a dívida no alto da fila', (
    tester,
  ) async {
    final journal = await _openDebts(tester);
    await _loan(tester, 'Carnê da loja');
    await _loan(tester, 'Empréstimo Banco X');

    await _tap(tester, find.text('Empréstimo Banco X'));
    await _tap(tester, find.text('Quitar esta primeiro'));

    final ordered = (await journal.readAll()).whereType<DebtOrdered>();
    expect(ordered, hasLength(1));
    expect(find.text('Quitar esta primeiro'), findsNothing);
  });
}
