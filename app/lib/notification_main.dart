import 'dart:async';
import 'dart:ui' show DartPluginRegistrant;

import 'package:cajui/src/app/composition.dart';
import 'package:cajui/src/core/storage/event_store_opener.dart';
import 'package:cajui/src/features/home_widget/application/home_widget_providers.dart';
import 'package:cajui/src/features/notifications/application/notification_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A leitura das notificações do banco com o app fechado (ADR-025).
///
/// O leitor de notificações do Android acorda o Cajui sem abrir tela: o
/// lado nativo sobe um motor do Flutter sem janela, que roda
/// `notificationMain` — a porta declarada em `main.dart` — e isto aqui. É o
/// mesmo livro, o mesmo registro cifrado, as mesmas regras do app aberto.
///
/// O registro só aceita **um escritor por vez** (ADR-004): duas cópias
/// gravando juntas quebrariam o encadeamento das linhas. Por isso o app que
/// abre espera esta leitura terminar ([waitIdle]), e o lado nativo, quando
/// o app abre no meio dela, pede para parar na próxima notificação.
abstract final class BackgroundRun {
  static const _channel = MethodChannel('app.cajui/background');

  /// O máximo que o app espera ao abrir. O lado nativo encerra a leitura
  /// em segundo plano bem antes disso; o teto é só para o app nunca ficar
  /// preso na abertura.
  static const maxWait = Duration(seconds: 15);

  /// Espera a leitura em segundo plano terminar, se houver uma. Fora do
  /// Android, ou sem o lado nativo, volta na hora.
  static Future<void> waitIdle() async {
    try {
      await _channel.invokeMethod<void>('waitIdle').timeout(maxWait);
    } on TimeoutException {
      return;
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  /// Esvazia a fila, atualiza o widget e avisa o lado nativo que acabou —
  /// sempre, mesmo que algo falhe no meio: é o aviso que libera o app.
  static Future<void> run() async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    try {
      await _drain();
    } finally {
      await _finished();
    }
  }

  static Future<void> _drain() async {
    final store = await openEventStore();
    final container = ProviderContainer(
      overrides: Composition.overrides(store: store, nativeCapture: true),
    );
    try {
      await container.read(bankNoticeServiceProvider).drain();
      await container
          .read(homeSnapshotPublisherProvider)
          .publishFrom(container);
    } finally {
      container.dispose();
      await store.close();
    }
  }

  static Future<void> _finished() async {
    try {
      await _channel.invokeMethod<void>('finished');
    } on MissingPluginException {
      return;
    }
  }
}
