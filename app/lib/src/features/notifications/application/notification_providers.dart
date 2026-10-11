import 'package:cajui/src/features/notifications/application/bank_notice_device.dart';
import 'package:cajui/src/features/notifications/application/bank_notice_service.dart';
import 'package:cajui/src/features/notifications/application/launch_requests.dart';
import 'package:cajui/src/features/notifications/application/notice_announcement.dart';
import 'package:cajui/src/features/notifications/application/notice_recorder.dart';
import 'package:cajui/src/features/notifications/application/notification_access.dart';
import 'package:cajui/src/features/notifications/application/queued_notice.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A fila e os avisos das notificações do banco. A raiz do app liga ao
/// canal nativo no Android; sem ligação, nada chega e nada sai — é a web, e
/// é o teste que não fala de notificação.
final bankNoticeDeviceProvider = Provider<BankNoticeDevice>(
  (ref) => const _Silent(),
);

/// A permissão de ler as notificações, para a linha de Ajustes.
final notificationAccessProvider = Provider<NotificationAccess>(
  (ref) => const _Silent(),
);

/// As telas que as notificações do Cajui pedem para abrir.
final launchRequestsProvider = Provider<LaunchRequests>(
  (ref) => const _Silent(),
);

/// O que decide, para cada notificação, entre lançar e pedir um toque.
final noticeRecorderProvider = Provider<NoticeRecorder>(NoticeRecorder.new);

/// Quem esvazia a fila. Um por app: duas rodadas em paralelo escreveriam
/// o livro ao mesmo tempo.
final bankNoticeServiceProvider = Provider<BankNoticeService>(
  BankNoticeService.new,
);

/// Nenhuma notificação: o aparelho não tem leitor, ou o teste não usa.
final class _Silent
    implements BankNoticeDevice, NotificationAccess, LaunchRequests {
  const new();

  @override
  Stream<void> get arrivals => const Stream.empty();

  @override
  Future<List<QueuedNotice>> take() async => const [];

  @override
  Future<void> ack(Iterable<String> ids) async {}

  @override
  Future<void> announce(NoticeAnnouncement announcement) async {}

  @override
  bool get stopRequested => false;

  @override
  bool get isSupported => false;

  @override
  Future<bool> isGranted() async => false;

  @override
  Future<void> openSettings() async {}

  @override
  Future<String?> takePending() async => null;

  @override
  Stream<String> get requests => const Stream.empty();
}
