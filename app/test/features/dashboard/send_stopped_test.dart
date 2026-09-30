import 'package:cajui/src/app/cajui_app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_enrollment.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _open(
  WidgetTester tester, {
  required bool quietSend,
  FakeEnrollment? enrollment,
}) async {
  tester.view.physicalSize = const Size(390, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(
        journal: MemoryLedgerJournal(samplePlanEvents),
        quietSend: quietSend,
        enrollment: enrollment,
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
    expect(find.textContaining('ainda não está cadastrado'), findsNothing);
  });

  testWidgets('ADR-008 · aparelho que o servidor não conhece ouve que falta '
      'o cadastro, e não que falta a digital', (tester) async {
    await _open(
      tester,
      quietSend: false,
      enrollment: FakeEnrollment(refused: true),
    );

    expect(
      find.text('Este celular ainda não está cadastrado no servidor.'),
      findsOneWidget,
    );
    expect(find.text('O envio automático está parado.'), findsNothing);
    expect(find.textContaining('digital'), findsNothing);
  });

  testWidgets('ADR-008 · o aviso leva ao cadastro, e o cadastro leva ao '
      'envio', (tester) async {
    final enrollment = FakeEnrollment(refused: true);
    await _open(tester, quietSend: false, enrollment: enrollment);

    await tester.tap(find.text('Cadastrar este aparelho'));
    await _settle(tester);
    await tester.enterText(find.byType(EditableText).first, 'ABC123XYZ0');
    await tester.pump();
    await tester.tap(find.text('Cadastrar'));
    await _settle(tester);

    expect(enrollment.codes, ['ABC123XYZ0']);
    expect(enrollment.isRefused, isFalse);
    expect(find.text('Enviar ao servidor'), findsOneWidget);
  });
}
