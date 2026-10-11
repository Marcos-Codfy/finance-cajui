import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/receipts/application/shared_item.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_inbox.dart';
import '../../support/household_book.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/test_scope.dart';

/// Deixa leitura, classificação e troca de tela terminarem. `pumpAndSettle`
/// não serve: os pontos de "carregando" pulsam sem parar.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

/// Um comprovante de Pix de hoje, no formato com rótulos. Dados inventados.
String _pix(String to, String amount) =>
    'Pix enviado\nFavorecido: $to\nValor: R\$ $amount\nData: 20/09/2026';

/// Abre o app com [events] no livro e compartilha [text].
Future<MemoryLedgerJournal> _share(
  WidgetTester tester,
  List<LedgerEvent> events,
  String text,
) async {
  tester.view.physicalSize = const Size(390, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final inbox = FakeInbox();
  final journal = MemoryLedgerJournal(events);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(inbox: inbox, journal: journal),
      child: const CajuiApp(),
    ),
  );
  await _settle(tester);
  inbox.share([SharedText(id: 'c1', text: text)]);
  await _settle(tester);
  return journal;
}

void main() {
  testWidgets(r'RN-1076 · a notificação lançou ontem R$ 150,00 "Joana P '
      'Lima"; o comprovante de hoje para JOANA PEREIRA LIMA avisa, e "É o '
      'mesmo" não grava nada', (tester) async {
    final journal = await _share(tester, [
      recordedEntry(
        id: 'notice-n1',
        cents: 15000,
        on: testYesterday,
        description: 'Joana P Lima',
      ),
    ], _pix('JOANA PEREIRA LIMA', '150,00'));

    expect(
      find.textContaining('A notificação do banco já lançou'),
      findsOneWidget,
    );
    expect(find.textContaining('Joana P Lima, ontem, em Outros.'), findsOne);
    expect(find.text('É outro — lançar'), findsOneWidget);
    expect(find.text('Lançar'), findsOneWidget, reason: 'aviso, não bloqueio');

    await tester.tap(find.text('É o mesmo — não lançar'));
    await _settle(tester);

    expect(find.text('Conferir comprovante'), findsNothing);
    expect(await journal.readAll(), hasLength(1), reason: 'RN-723');
  });

  testWidgets('RN-1076 · "É outro — lançar" lança este também', (tester) async {
    final journal = await _share(tester, [
      recordedEntry(
        id: 'notice-n1',
        cents: 850,
        on: testToday,
        description: 'Padaria Central do Bai',
        categoryId: 'bakery',
      ),
    ], _pix('PADARIA CENTRAL DO BAIRRO LTDA', '8,50'));

    expect(find.textContaining('hoje, em Padaria.'), findsOneWidget);
    expect(
      find.textContaining('Já existe um lançamento'),
      findsNothing,
      reason: 'o aviso da notificação toma o lugar do da RN-221',
    );

    await tester.tap(find.text('É outro — lançar'));
    await _settle(tester);

    expect(find.text('Conferir comprovante'), findsNothing);
    expect((await journal.readAll()).whereType<EntryRecorded>(), hasLength(2));
  });

  testWidgets('RN-1074 · comprovante de Pix para MARCOS VINICIUS MUNIZ '
      'ARRUDA, nome da casa: avisa e deixa não lançar em um toque', (
    tester,
  ) async {
    final journal = await _share(tester, [
      householdOf(const [testHouseholdName]),
    ], _pix('MARCOS VINICIUS MUNIZ ARRUDA', '500,00'));

    expect(
      find.textContaining(
        'para Marcos Vinicius Muniz Arruda parece transferência entre '
        'contas da casa.',
      ),
      findsOneWidget,
    );
    expect(find.text('Lançar'), findsOneWidget, reason: 'aviso, não bloqueio');

    await tester.tap(find.text('Não lançar'));
    await _settle(tester);

    expect(find.text('Conferir comprovante'), findsNothing);
    expect(await journal.readAll(), hasLength(1), reason: 'RN-723');
  });

  testWidgets('RN-1074 · Pix para outra pessoa não traz o aviso da casa', (
    tester,
  ) async {
    await _share(tester, [
      householdOf(const [testHouseholdName]),
    ], _pix('MARCOS SILVA', '500,00'));

    expect(find.textContaining('entre contas da casa'), findsNothing);
    expect(find.text('Conferir comprovante'), findsOneWidget);
  });
}
