import 'package:flutter/material.dart' show DefaultMaterialLocalizations;
import 'package:flutter/widgets.dart';

/// Os textos de sistema que os componentes pedem ao Flutter.
///
/// O campo de texto do design system usa o do Material por dentro, e ele
/// exige estas localizações. Ficam aqui para o app não precisar importar o
/// Material só por causa disso — nem saber que ele existe.
abstract final class CajuiLocalizations {
  /// O que o `WidgetsApp` recebe em `localizationsDelegates`.
  static const List<LocalizationsDelegate<Object?>> delegates = [
    DefaultMaterialLocalizations.delegate,
    DefaultWidgetsLocalizations.delegate,
  ];
}
