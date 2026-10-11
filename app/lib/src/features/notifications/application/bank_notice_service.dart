import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/notifications/application/bank_notice_device.dart';
import 'package:cajui/src/features/notifications/application/notice_announcement.dart';
import 'package:cajui/src/features/notifications/application/notification_providers.dart';
import 'package:cajui/src/features/notifications/application/queued_notice.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Esvazia a fila das notificações do banco (ADR-025): lê cada uma, lança o
/// que dá para lançar, desfaz o que a pessoa pediu e posta os avisos.
///
/// Roda no app aberto, quando o lado nativo avisa que chegou algo, e no
/// motor de segundo plano, quando o app está fechado — o mesmo código, com
/// o mesmo livro.
class BankNoticeService {
  /// Cria o serviço sobre os providers de [ref].
  new(this.ref);

  /// De onde saem a fila e o livro.
  final Ref ref;

  Future<void>? _running;
  bool _again = false;

  /// O motivo gravado quando a pessoa toca em Desfazer.
  static const undoReason = 'Desfeito pela notificação';

  BankNoticeDevice get _device => ref.read(bankNoticeDeviceProvider);

  /// Trata tudo o que está na fila. Pedido no meio de uma rodada não abre
  /// outra em paralelo: a rodada em curso dá mais uma volta no fim, e o
  /// livro só tem um escritor por vez.
  Future<void> drain() {
    final running = _running;
    if (running != null) {
      _again = true;
      return running;
    }
    return _running = _rounds().whenComplete(() => _running = null);
  }

  Future<void> _rounds() async {
    do {
      _again = false;
      await _round();
    } while (_again && !_device.stopRequested);
  }

  Future<void> _round() async {
    final device = _device;
    for (final notice in await device.take()) {
      if (device.stopRequested) return;
      await _handle(notice);
      await device.ack([notice.id]);
    }
  }

  /// Uma notificação que não deu para tratar não trava as outras, e nada
  /// dela vai para log nenhum: o texto tem valor e nome (RN-797). A
  /// notificação do banco continua no celular, e lançar à mão resolve.
  Future<void> _handle(QueuedNotice notice) async {
    try {
      final announcement = switch (notice) {
        BankNotice(:final id, :final notification) => await _read(
          id,
          notification,
        ),
        UndoNotice(:final entryId) => await _undo(entryId),
      };
      if (announcement != null) await _device.announce(announcement);
    } on Exception {
      return;
    }
  }

  Future<NoticeAnnouncement?> _read(
    String id,
    BankNotification notification,
  ) async {
    final reading = BankNotificationParser.read(notification);
    if (reading == null) return null;
    return await ref.read(noticeRecorderProvider).handle(id, reading);
  }

  /// Desfazer é cancelar (RN-208): o lançamento sai de toda conta, e o fato
  /// fica no registro. Lançamento que já não existe não faz nada.
  Future<NoticeAnnouncement?> _undo(String entryId) async {
    await ref.read(ledgerProvider.notifier).cancel(entryId, reason: undoReason);
    return null;
  }
}
