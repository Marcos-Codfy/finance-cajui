import 'package:cajui/src/features/reminders/application/reminder_routes.dart';
import 'package:cajui/src/features/reminders/infrastructure/native_reminder_schedule.dart';
import 'package:domain/domain.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A ponte com os alarmes do Android: o que atravessa o canal é o contrato
/// com `ReminderChannel.kt`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('teste/lembretes');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'canPost' ? false : null;
        });
  });

  final rent = DueReminder(
    id: 'bills:aluguel:2026-10-10:2',
    eventKey: 'bills:aluguel:2026-10-10',
    fireOn: LocalDate(2026, 10, 8),
    hour: 9,
    dueOn: LocalDate(2026, 10, 10),
    title: 'Aluguel vence sábado, 10',
    text: 'Texto',
    publicTitle: 'Uma conta vence sábado, 10',
    publicText: 'Desbloqueie para ver o valor.',
    target: ReminderTarget.bills,
    oncePerEvent: true,
  );

  test('RN-1081 · o lembrete vai com a hora no relógio do aparelho e some '
      'no fim do dia do vencimento', () async {
    await const NativeReminderSchedule(channel: channel).replace([rent]);

    final call = calls.single;
    expect(call.method, 'replace');
    final item = ((call.arguments as Map)['items'] as List).single as Map;
    expect(item['fireAt'], DateTime(2026, 10, 8, 9).millisecondsSinceEpoch);
    expect(item['expiresAt'], DateTime(2026, 10, 11).millisecondsSinceEpoch);
    expect(item['eventKey'], 'bills:aluguel:2026-10-10');
    expect(item['publicTitle'], 'Uma conta vence sábado, 10');
    expect(item['oncePerEvent'], isTrue);
  });

  test('RN-849 RN-1087 · a rota do toque leva o assunto e volta '
      'igual', () async {
    await const NativeReminderSchedule(channel: channel).replace([rent]);
    final item =
        ((calls.single.arguments as Map)['items'] as List).single as Map;

    expect(item['route'], 'reminder:bills');
    expect(
      ReminderRoutes.targetOf(item['route'] as String),
      ReminderTarget.bills,
    );
    expect(ReminderRoutes.targetOf('review'), isNull);
    expect(ReminderRoutes.targetOf('reminder:outra'), isNull);
  });

  test('lista vazia desmarca tudo; o lado que falta vira "não pode"', () async {
    const schedule = NativeReminderSchedule(channel: channel);
    await schedule.replace(const []);

    expect((calls.single.arguments as Map)['items'], isEmpty);
    expect(await schedule.canPost(), isFalse);
    expect(
      await const NativeReminderSchedule(
        channel: MethodChannel('teste/sem-lado-nativo'),
      ).canPost(),
      isFalse,
    );
  });
}
