import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/reminders/application/reminders_providers.dart';
import 'package:cajui/src/features/reminders/presentation/due_reminders_row.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/home_navigation.dart';
import '../../support/test_scope.dart';
import 'fake_reminder_schedule.dart';

const _title = DueRemindersRow.title;

Future<void> _openSettings(
  WidgetTester tester, {
  FakeReminderSchedule? schedule,
}) async {
  tester.view.physicalSize = const Size(400, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...testOverrides(),
        if (schedule != null)
          reminderScheduleProvider.overrideWithValue(schedule),
      ],
      child: const CajuiApp(),
    ),
  );
  await tester.pump();
  await openFromHome(tester, 'Ajustes');
}

Finder _switch() => find.descendant(
  of: find.widgetWithText(CajuiListRow, _title),
  matching: find.byType(CajuiSwitch),
);

void main() {
  testWidgets('RN-1088 · a chave nasce ligada e diz o que faz; desligada, '
      'diz que nada chega', (tester) async {
    final schedule = FakeReminderSchedule();
    await _openSettings(tester, schedule: schedule);

    expect(find.text(_title), findsOneWidget);
    expect(find.textContaining('Dois dias antes e no dia'), findsOneWidget);

    await tester.ensureVisible(_switch());
    await tester.tap(_switch());
    await tester.pump();

    expect(
      find.textContaining('nenhum aviso de conta a vencer'),
      findsOneWidget,
    );
    expect(schedule.replaced.last, isEmpty);
  });

  testWidgets('RN-1088 · com o Android segurando as notificações, a linha '
      'diz isso e o toque pede para liberar', (tester) async {
    final schedule = FakeReminderSchedule()..posting = false;
    await _openSettings(tester, schedule: schedule);
    await tester.pump();

    expect(find.textContaining('segurando as notificações'), findsOneWidget);

    await tester.tap(find.textContaining('segurando as notificações'));
    await tester.pump();

    expect(schedule.asked, 1);
  });

  testWidgets('RN-1088 · ligar sem permissão já pede a permissão', (
    tester,
  ) async {
    final schedule = FakeReminderSchedule()..posting = false;
    await _openSettings(tester, schedule: schedule);
    await tester.ensureVisible(_switch());
    await tester.tap(_switch());
    await tester.pump();
    await tester.tap(_switch());
    await tester.pump();

    expect(schedule.asked, 1);
  });

  testWidgets('fora do Android, a linha não aparece', (tester) async {
    await _openSettings(tester);

    expect(find.text(_title), findsNothing);
  });
}
