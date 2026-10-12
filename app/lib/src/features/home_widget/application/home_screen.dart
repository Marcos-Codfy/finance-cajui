import 'package:cajui/src/features/home_widget/application/home_snapshot.dart';
import 'package:cajui/src/features/home_widget/application/widget_placement.dart';

/// A tela inicial do celular, onde mora o widget do Cajui.
///
/// No Android, o canal `app.cajui/home`; na web e nos testes, lugar nenhum.
abstract interface class HomeScreen {
  /// Deixa [snapshot] para o widget e para o aviso de domingo.
  Future<void> publish(HomeSnapshot snapshot);

  /// Se o widget já está na tela inicial, e se dá para pedir que vá.
  Future<WidgetPlacement> placement();

  /// Pede ao launcher para pôr o widget: o sistema mostra a confirmação, e
  /// é a pessoa quem decide.
  Future<void> pin();
}
