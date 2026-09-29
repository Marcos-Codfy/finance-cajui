import 'package:cajui/src/app/cajui_app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _open(WidgetTester tester, {required bool quietSend}) async {
  tester.view.physicalSize = const Size(390, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(
        journal: MemoryLedgerJournal(samplePlanEvents),
        quietSend: quietSend,
      ),
      child: const CajuiApp(),
    ),
  );
  await _settle(tester);
}

void main() {
  testWidgets('BL-061 · com o envio automático parado, o painel diz isso e '
      'leva ao envio', (tester) async {
    await _open(tester, quietSend: false);

    expect(find.text('O envio automático está parado.'), findsOneWidget);
    expect(
      find.textContaining('ele pede a digital uma vez por dia'),
      findsOneWidget,
    );

    await tester.tap(find.text('Enviar agora'));
    await _settle(tester);

    expect(find.text('Enviar ao servidor'), findsOneWidget);
  });

  testWidgets('BL-061 · com o envio automático funcionando, nada é dito', (
    tester,
  ) async {
    await _open(tester, quietSend: true);

    expect(find.text('O envio automático está parado.'), findsNothing);
  });
}
