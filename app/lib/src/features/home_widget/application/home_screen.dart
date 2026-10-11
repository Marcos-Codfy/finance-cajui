import 'package:cajui/src/features/home_widget/application/home_snapshot.dart';

/// A tela inicial do celular, onde mora o widget do Cajui.
///
/// No Android, o canal `app.cajui/home`; na web e nos testes, lugar nenhum.
abstract interface class HomeScreen {
  /// Deixa [snapshot] para o widget e para o aviso de domingo.
  Future<void> publish(HomeSnapshot snapshot);
}
