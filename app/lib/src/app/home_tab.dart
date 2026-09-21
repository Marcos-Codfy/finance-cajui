import 'package:design_system/design_system.dart';

/// As áreas do app, na ordem em que aparecem na barra de navegação.
///
/// A ordem é a da frequência de uso: o painel responde "como estou?", os
/// lançamentos respondem "o que gastei?", e o resto vem depois.
enum HomeTab {
  /// O mês de relance: sobra, limites e o que vence.
  dashboard(CajuiIconData.chart, 'Painel'),

  /// O que foi lançado, e a porta para lançar à mão.
  entries(CajuiIconData.receipt, 'Lançamentos'),

  /// A conversa com o assistente.
  assistant(CajuiIconData.chat, 'Assistente'),

  /// Som, vibração e o que mais se regula.
  settings(CajuiIconData.sliders, 'Ajustes');

  new(this.icon, this.label);

  /// O desenho da aba.
  final CajuiIconData icon;

  /// O nome da aba, sempre à vista.
  final String label;

  /// A aba como destino da barra de navegação.
  CajuiNavDestination get destination =>
      CajuiNavDestination(icon: icon, label: label);
}
