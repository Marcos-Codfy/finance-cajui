import 'package:cajui/src/app/cajui_app.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Na web o Flutter só monta a árvore de acessibilidade quando alguém pede,
  // e leitor de tela não sabe pedir. Ligada desde o início, a página nasce
  // legível para ele (ADR-013).
  if (kIsWeb) SemanticsBinding.instance.ensureSemantics();
  runApp(const ProviderScope(child: CajuiApp()));
}
