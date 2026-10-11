import 'dart:async';

import 'package:cajui/src/features/notifications/application/bank_notice_device.dart';
import 'package:cajui/src/features/notifications/application/launch_requests.dart';
import 'package:cajui/src/features/notifications/application/notice_announcement.dart';
import 'package:cajui/src/features/notifications/application/notification_access.dart';
import 'package:cajui/src/features/notifications/application/queued_notice.dart';
import 'package:domain/domain.dart';

import '../../support/test_scope.dart';

/// O lado nativo das notificações, de mentira: a fila é uma lista, e o que
/// o app avisa fica guardado para o teste conferir.
final class FakeNoticeDevice
    implements BankNoticeDevice, NotificationAccess, LaunchRequests {
  /// O que espera na fila.
  final queue = <QueuedNotice>[];

  /// O que o app disse que tratou, na ordem.
  final acked = <String>[];

  /// Os avisos postados, na ordem.
  final announced = <NoticeAnnouncement>[];

  /// Se o acesso às notificações foi dado.
  bool granted = false;

  /// Quantas vezes a tela do sistema foi aberta.
  int settingsOpened = 0;

  /// A tela pedida na abertura.
  String? pendingRoute;

  /// Se o lado nativo pediu para parar.
  bool stop = false;

  final _arrivals = StreamController<void>.broadcast();
  final _requests = StreamController<String>.broadcast();

  /// Põe [notice] na fila e avisa, como o leitor do Android faz.
  void push(QueuedNotice notice) {
    queue.add(notice);
    _arrivals.add(null);
  }

  /// Pede [route] com o app aberto, como o toque num aviso.
  void request(String route) => _requests.add(route);

  @override
  Stream<void> get arrivals => _arrivals.stream;

  @override
  Future<List<QueuedNotice>> take() async => List.of(queue);

  @override
  Future<void> ack(Iterable<String> ids) async {
    final done = ids.toSet();
    acked.addAll(done);
    queue.removeWhere((notice) => done.contains(notice.id));
  }

  @override
  Future<void> announce(NoticeAnnouncement announcement) async =>
      announced.add(announcement);

  @override
  bool get stopRequested => stop;

  @override
  bool get isSupported => true;

  @override
  Future<bool> isGranted() async => granted;

  @override
  Future<void> openSettings() async => settingsOpened++;

  @override
  Future<String?> takePending() async {
    final route = pendingRoute;
    pendingRoute = null;
    return route;
  }

  @override
  Stream<String> get requests => _requests.stream;
}

/// Uma notificação fictícia de [app], chegada em [on] — por padrão, o dia
/// dos testes.
BankNotice bankNotice(
  String id,
  BankApp app,
  String text, {
  String title = '',
  LocalDate? on,
}) => BankNotice(
  id: id,
  notification: BankNotification(
    packageName: app.packageNames.first,
    title: title,
    text: text,
    postedOn: on ?? testToday,
  ),
);
