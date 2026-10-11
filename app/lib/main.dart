import 'package:cajui/notification_main.dart';
import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/app/composition.dart';
import 'package:cajui/src/core/storage/event_store_opener.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A raiz do app: abre o registro do aparelho e liga cada porta da aplicação
/// ao adaptador que vale nesta plataforma.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Na web o Flutter só monta a árvore de acessibilidade quando alguém pede,
  // e leitor de tela não sabe pedir. Ligada desde o início, a página nasce
  // legível para ele (ADR-013).
  if (kIsWeb) SemanticsBinding.instance.ensureSemantics();
  // Receber compartilhamento e ler comprovante só existem no Android
  // (ADR-006 e ADR-007). Na web, que é modo consulta, nunca chega nada.
  final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  // Um escritor por vez no registro: se a leitura das notificações do banco
  // estiver gravando com o app fechado, o app espera ela terminar antes de
  // abrir o registro (ADR-025).
  if (android) await BackgroundRun.waitIdle();
  final store = await openEventStore();
  runApp(
    ProviderScope(
      overrides: Composition.overrides(store: store, nativeCapture: android),
      child: const CajuiApp(),
    ),
  );
}

/// A porta do motor sem janela que o lado nativo sobe quando chega a
/// notificação de um banco com o app fechado (ADR-025). O nome é o contrato
/// com `NoticeRouter.kt`; a anotação impede que a compilação a descarte.
@pragma('vm:entry-point')
Future<void> notificationMain() => BackgroundRun.run();
