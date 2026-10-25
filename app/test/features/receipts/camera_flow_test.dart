import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/receipts/application/read_outcome.dart';
import 'package:cajui/src/features/receipts/application/shared_item.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_inbox.dart';
import '../../support/fake_reader.dart';
import '../../support/home_navigation.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await _settle(tester);
}

/// O texto de um cupom de mercado, como o OCR devolveria da foto.
const _cupom = r'''
MAR DOCE SUPERMERCADOS LTDA
CNPJ: 11.222.333/0001-81
AV JOAQUIM EXEMPLO,5500,PLANO DIRETOR SUL,PALMAS
Documento Auxiliar da Nota Fiscal de Consumidor Eletronica
AR009803 ACUCAR CRISTAL 1X400G 1 UND 13,90 13,90
Valor total R\$ 664,41
Desconto total R\$ 10,83
Valor a Pagar R\$ 653,58''';

Future<FakeInbox> _openEntries(
  WidgetTester tester, {
  bool hasCamera = true,
}) async {
  tester.view.physicalSize = const Size(390, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final inbox = FakeInbox()..hasCamera = hasCamera;
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(
        journal: MemoryLedgerJournal(samplePlanEvents),
        inbox: inbox,
        reader: FakeReader(const {'/inbox/foto-1': ReadText(_cupom)}),
      ),
      child: const CajuiApp(),
    ),
  );
  await tester.pump();
  await openFromHome(tester, 'Lançamentos');
  return inbox;
}

void main() {
  testWidgets('ADR-017 · fotografar o cupom abre a conferência já lida, como '
      'se tivesse sido compartilhado', (tester) async {
    final inbox = await _openEntries(tester);
    inbox.photo = const [
      SharedFile(id: 'foto-1', path: '/inbox/foto-1', isPdf: false),
    ];

    await _tap(tester, find.text('Fotografar'));

    expect(inbox.photoRequests, 1);
    expect(find.text('Conferir comprovante'), findsOneWidget);
    // O cupom traz o valor pago, o nome da loja e a categoria do ramo.
    expect(find.text('653,58'), findsOneWidget);
    expect(find.text('Mar Doce Supermercados'), findsOneWidget);
    // O ramo do nome já vem no campo: supermercado é mercado. Nada mais a
    // tocar além de "Lançar".
    expect(find.text('Mercado'), findsOneWidget);
    expect(find.textContaining('parece mercado'), findsNothing);
    expect(find.widgetWithText(CajuiChip, 'Mercado'), findsNothing);
  });

  testWidgets('escolher da galeria: o print escolhido abre a conferência já '
      'lida, pelo mesmo caminho da foto', (tester) async {
    final inbox = await _openEntries(tester);
    inbox.picked = const [
      SharedFile(id: 'foto-1', path: '/inbox/foto-1', isPdf: false),
    ];

    await _tap(tester, find.text('Da galeria'));

    expect(inbox.pickRequests, 1);
    expect(find.text('Conferir comprovante'), findsOneWidget);
    expect(find.text('653,58'), findsOneWidget);
  });

  testWidgets('o Início também tem a galeria, no alto', (tester) async {
    final inbox = await _openEntries(tester);
    inbox.picked = const [
      SharedFile(id: 'foto-1', path: '/inbox/foto-1', isPdf: false),
    ];
    await backToTabs(tester);
    await _tap(tester, find.bySemanticsLabel('Painel'));

    await _tap(
      tester,
      find.bySemanticsLabel('Escolher da galeria ou dos arquivos'),
    );

    expect(inbox.pickRequests, 1);
    expect(find.text('Conferir comprovante'), findsOneWidget);
  });

  testWidgets('aparelho sem câmera mostra só a galeria', (tester) async {
    await _openEntries(tester, hasCamera: false);

    expect(find.text('Fotografar'), findsNothing);
    expect(find.text('Da galeria'), findsOneWidget);
    expect(find.text('Lançar'), findsOneWidget);
  });
}
