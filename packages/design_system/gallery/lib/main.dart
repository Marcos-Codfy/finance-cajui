import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/app/gallery_app.dart';

/// Ponto de entrada da gallery, o sample navegável do design system.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Na web o Flutter só monta a árvore de acessibilidade depois de um clique
  // num botão escondido. Aqui ela nasce ligada (RNF-WEB-03): leitor de tela
  // funciona de primeira, e toda medição de desempenho já paga esse custo.
  if (kIsWeb) SemanticsBinding.instance.ensureSemantics();
  runApp(const GalleryApp());
}
