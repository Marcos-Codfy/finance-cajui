import 'dart:io';

import 'package:cajui/src/features/notifications/application/notice_announcement.dart';
import 'package:cajui/src/features/notifications/application/queued_notice.dart';
import 'package:cajui/src/features/notifications/infrastructure/native_notifications_channel.dart';
import 'package:cajui/src/features/notifications/infrastructure/queued_notice_codec.dart';
import 'package:domain/domain.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A ponte com o lado nativo: o que atravessa o canal é entrada não
/// confiável, e o que não abre não pode travar a fila.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final postedAt = DateTime(2026, 9, 20, 14, 30).millisecondsSinceEpoch;

  group('o item da fila', () {
    test('a notificação do banco vira a notificação do domínio', () {
      final notice =
          QueuedNoticeCodec.decode({
                'id': 'n1',
                'type': 'bank',
                'package': 'com.nu.production',
                'title': 'Compra aprovada',
                'text': r'Compra de R$ 45,90 APROVADA em LOJA X',
                'postedAt': postedAt,
              })!
              as BankNotice;

      expect(notice.id, 'n1');
      expect(notice.notification.packageName, 'com.nu.production');
      expect(notice.notification.postedOn, LocalDate(2026, 9, 20));
    });

    test('o Desfazer vira o pedido de cancelar', () {
      final notice = QueuedNoticeCodec.decode({
        'id': 'undo-notice-n1',
        'type': 'undo',
        'entryId': 'notice-n1',
      });

      expect(notice, isA<UndoNotice>());
      expect((notice! as UndoNotice).entryId, 'notice-n1');
    });

    test('campo que falta vira item ilegível, nunca exceção', () {
      expect(QueuedNoticeCodec.decode({'type': 'bank'}), isNull);
      expect(QueuedNoticeCodec.decode({'id': 'x', 'type': 'bank'}), isNull);
      expect(QueuedNoticeCodec.decode({'id': 'x', 'type': 'outro'}), isNull);
      expect(QueuedNoticeCodec.decode({'id': 'x', 'type': 'undo'}), isNull);
    });

    test('texto comprido é cortado no teto', () {
      final notice =
          QueuedNoticeCodec.decode({
                'id': 'n1',
                'type': 'bank',
                'package': 'com.nu.production',
                'text': 'a' * 5000,
                'postedAt': postedAt,
              })!
              as BankNotice;

      expect(
        notice.notification.text,
        hasLength(QueuedNoticeCodec.maxTextLength),
      );
    });

    test('o aviso vai para o lado nativo com o que ele precisa', () {
      expect(
        QueuedNoticeCodec.encode(
          const RecordedAnnouncement(entryId: 'e1', title: 'T', text: 'X'),
        ),
        {'kind': 'recorded', 'entryId': 'e1', 'title': 'T', 'text': 'X'},
      );
      expect(
        QueuedNoticeCodec.encode(
          const AskAnnouncement(
            noticeId: 'n1',
            shareText: 'S',
            title: 'T',
            text: 'X',
          ),
        )['shareText'],
        'S',
      );
    });
  });

  test('o que não abre sai da fila na hora: ficaria lá para sempre', () async {
    const channel = MethodChannel('teste/notificacoes');
    final acked = <Object?>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'ack') acked.add(call.arguments);
          if (call.method != 'take') return null;
          return [
            {'id': 'ruim', 'type': 'bank'},
            {'id': 'u1', 'type': 'undo', 'entryId': 'e1'},
          ];
        });

    final items = await NativeNotificationsChannel(channel: channel).take();

    expect(items.single.id, 'u1');
    expect(acked, [
      {
        'ids': ['ruim'],
      },
    ]);
  });

  test('sem o lado nativo, nada chega e nada quebra', () async {
    final native = NativeNotificationsChannel(
      channel: const MethodChannel('teste/sem-ninguem'),
    );

    expect(await native.take(), isEmpty);
    expect(await native.isGranted(), isFalse);
    expect(await native.takePending(), isNull);
  });

  test('a lista de bancos é a mesma dos dois lados: o que o Android deixa '
      'passar, o domínio sabe ler', () {
    final kotlin = File(
      'android/app/src/main/kotlin/app/cajui/notifications/BankApps.kt',
    ).readAsStringSync();
    final native = {
      for (final match in RegExp('"([a-zA-Z0-9_.]+)"').allMatches(kotlin))
        match.group(1)!,
    };

    expect(native, BankApp.allPackages);
  });
}
