import 'package:cajui/src/features/home/presentation/sync_badge.dart';
import 'package:cajui/src/features/ledger/application/sync_status.dart';
import 'package:cajui/src/features/ledger/application/sync_status_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.utc(2026, 10, 17, 17, 32);

  group('o selo de sincronização do Início', () {
    test('antes da primeira conversa com o servidor, o selo não aparece', () {
      expect(SyncBadge.wordsOf(const SyncStatus(), now: now), isNull);
    });

    test('sincronizando, sincronizado agora, e a hora da casa depois', () {
      expect(
        SyncBadge.wordsOf(const SyncStatus(running: true), now: now),
        'Sincronizando…',
      );
      expect(
        SyncBadge.wordsOf(SyncStatus(lastOkAt: now), now: now),
        'Sincronizado agora',
      );
      // 17h32 em UTC é 14h32 na casa (UTC−3).
      expect(
        SyncBadge.wordsOf(
          SyncStatus(lastOkAt: now),
          now: now.add(const Duration(minutes: 5)),
        ),
        'Sincronizado às 14h32',
      );
    });

    test('a falha diz que o lançado fica guardado, sem alarme', () {
      final words = SyncBadge.wordsOf(
        SyncStatus(lastOkAt: now, failing: true),
        now: now,
      )!;

      expect(words, contains('sobe depois'));
      expect(words, isNot(contains('!')));
    });

    test('o controle anota começo, acerto e falha', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final status = container.read(syncStatusProvider.notifier)..started();

      expect(container.read(syncStatusProvider).running, isTrue);
      status.finished(ok: true, at: now);
      expect(container.read(syncStatusProvider).lastOkAt, now);
      status.finished(ok: false, at: now);
      final failed = container.read(syncStatusProvider);
      expect(failed.failing, isTrue);
      expect(failed.lastOkAt, now);
    });
  });
}
