import 'package:cajui/src/features/home_widget/application/home_screen.dart';
import 'package:cajui/src/features/home_widget/application/home_snapshot.dart';
import 'package:cajui/src/features/home_widget/application/widget_placement.dart';
import 'package:flutter/services.dart';

/// O widget da tela inicial no Android, pelo canal `app.cajui/home`
/// (ADR-025). O lado nativo guarda o retrato, redesenha o widget e marca o
/// aviso de domingo.
final class NativeHomeScreen implements HomeScreen {
  /// Cria a porta. O canal entra por parâmetro para o teste simular o lado
  /// nativo.
  const new({this._channel = const MethodChannel('app.cajui/home')});

  final MethodChannel _channel;

  /// Widget que não atualiza não pode derrubar o app: o número volta certo
  /// na próxima publicação.
  @override
  Future<void> publish(HomeSnapshot snapshot) async {
    try {
      await _channel.invokeMethod<void>('publish', snapshot.toMap());
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }

  /// Sem resposta do lado nativo, a linha some: melhor não oferecer do que
  /// oferecer um botão que não faz nada.
  @override
  Future<WidgetPlacement> placement() async {
    try {
      return WidgetPlacement.of(
        await _channel.invokeMethod<String>('placement'),
      );
    } on MissingPluginException {
      return WidgetPlacement.unavailable;
    } on PlatformException {
      return WidgetPlacement.unavailable;
    }
  }

  @override
  Future<void> pin() async {
    try {
      await _channel.invokeMethod<bool>('pin');
    } on MissingPluginException {
      return;
    } on PlatformException {
      return;
    }
  }
}
