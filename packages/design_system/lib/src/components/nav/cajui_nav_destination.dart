import 'package:design_system/src/icons/cajui_icon_data.dart';
import 'package:flutter/foundation.dart';

/// Um destino da barra de navegação: o ícone e o nome que aparece sob ele.
@immutable
class CajuiNavDestination {
  /// Cria o destino [label] com o ícone [icon].
  const new({required this.icon, required this.label});

  /// O desenho do destino.
  final CajuiIconData icon;

  /// O nome do destino. Sempre visível: ícone sozinho obriga a adivinhar.
  final String label;
}
