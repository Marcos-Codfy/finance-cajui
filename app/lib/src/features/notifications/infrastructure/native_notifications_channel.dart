import 'dart:async';

import 'package:cajui/src/features/notifications/application/bank_notice_device.dart';
import 'package:cajui/src/features/notifications/application/launch_requests.dart';
import 'package:cajui/src/features/notifications/application/notice_announcement.dart';
import 'package:cajui/src/features/notifications/application/notification_access.dart';
import 'package:cajui/src/features/notifications/application/queued_notice.dart';
import 'package:cajui/src/features/notifications/infrastructure/queued_notice_codec.dart';
import 'package:flutter/services.dart';

/// As notificações do banco no Android, pelo canal `app.cajui/notifications`
/// (ADR-025).
///
/// Uma classe só atende as três portas porque o canal é um só: os avisos
/// que o lado nativo manda — "chegou algo", "abra a revisão", "pare" —
/// chegam todos pelo mesmo tratador, e um canal só tem um.
final class NativeNotificationsChannel
    implements BankNoticeDevice, NotificationAccess, LaunchRequests {
  /// Cria o canal. Ele entra por parâmetro para o teste simular o lado
  /// nativo.
  new({this._channel = const MethodChannel('app.cajui/notifications')}) {
    _channel.setMethodCallHandler(_onCall);
  }

  final MethodChannel _channel;
  final _arrivals = StreamController<void>.broadcast();
  final _requests = StreamController<String>.broadcast();
  bool _stop = false;

  Future<Object?> _onCall(MethodCall call) async {
    switch (call.method) {
      case 'pending':
        _arrivals.add(null);
      case 'route':
        final route = call.arguments;
        if (route is String) _requests.add(route);
      case 'stop':
        _stop = true;
    }
    return null;
  }

  @override
  Stream<void> get arrivals => _arrivals.stream;

  @override
  bool get stopRequested => _stop;

  @override
  Future<List<QueuedNotice>> take() async {
    final raw = await _ask<List<Object?>>('take') ?? const [];
    final items = [for (final item in raw) ?_decode(item)];
    final unreadable = raw.length - items.length;
    // O que não abre sai da fila já: ficaria lá para sempre.
    if (unreadable > 0) await ack(_idsOf(raw).difference(_idsOfItems(items)));
    return items;
  }

  static QueuedNotice? _decode(Object? item) =>
      item is Map ? QueuedNoticeCodec.decode(item) : null;

  static Set<String> _idsOf(List<Object?> raw) => {
    for (final item in raw)
      if (item is Map && item['id'] is String) item['id']! as String,
  };

  static Set<String> _idsOfItems(List<QueuedNotice> items) => {
    for (final item in items) item.id,
  };

  @override
  Future<void> ack(Iterable<String> ids) =>
      _ask<void>('ack', {'ids': ids.toList()});

  @override
  Future<void> announce(NoticeAnnouncement announcement) =>
      _ask<void>('announce', QueuedNoticeCodec.encode(announcement));

  @override
  bool get isSupported => true;

  @override
  Future<bool> isGranted() async => await _ask<bool>('isGranted') ?? false;

  @override
  Future<void> openSettings() => _ask<void>('openSettings');

  @override
  Future<String?> takePending() => _ask<String>('takeRoute');

  @override
  Stream<String> get requests => _requests.stream;

  /// O lado nativo que falta ou recusa vira "nada": a notificação do banco
  /// continua no celular, e nada aqui pode derrubar o app.
  Future<T?> _ask<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
