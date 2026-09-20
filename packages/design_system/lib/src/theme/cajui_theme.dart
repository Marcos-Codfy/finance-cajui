import 'package:design_system/src/theme/cajui_theme_data.dart';
import 'package:flutter/widgets.dart';

/// Entrega o tema em vigor à árvore de widgets.
///
/// É um `InheritedWidget` próprio, e não o `Theme` do Material, para o
/// design system não depender de nenhum kit de interface: os componentes leem
/// daqui, e só daqui.
class CajuiTheme extends InheritedWidget {
  /// Disponibiliza [data] para [child] e seus descendentes.
  const new({required this.data, required super.child, super.key});

  /// O tema em vigor.
  final CajuiThemeData data;

  /// O tema mais próximo acima de [context].
  ///
  /// Falha cedo e com mensagem clara se não houver nenhum: componente do
  /// design system sem tema é erro de montagem, não caso a contornar.
  static CajuiThemeData of(BuildContext context) {
    final theme = context.dependOnInheritedWidgetOfExactType<CajuiTheme>();
    assert(theme != null, 'Nenhum CajuiTheme acima deste widget.');
    return theme!.data;
  }

  @override
  bool updateShouldNotify(CajuiTheme oldWidget) => data != oldWidget.data;
}
