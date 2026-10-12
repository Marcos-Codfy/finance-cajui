import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/home/home_numbers.dart';
import 'package:gallery/src/pages/screens/shared/screen_tools.dart';

/// A tela da Juju como o app a monta: o nome no título, o mês de relance
/// acima dele — com as palavras do Início — e a câmera e a galeria no alto.
///
/// Fica plana, sem a rolagem em profundidade: o mais novo da conversa nasce
/// na borda de baixo, justo onde a rolagem curvaria (ADR-028).
class JujuScreen extends StatelessWidget {
  /// Cria a tela com a conversa [children] e o pé [footer].
  const new({
    required this.children,
    required this.footer,
    this.readOnly = false,
    this.controller,
    super.key,
  });

  /// A conversa, de cima para baixo.
  final List<Widget> children;

  /// O campo de pergunta, ou os botões do extrato.
  final Widget footer;

  /// A consulta pela web: sem câmera nem galeria.
  final bool readOnly;

  /// Quem leva a conversa até a fala mais nova.
  final ScrollController? controller;

  /// O nome que o leitor de tela diz antes de cada fala dela.
  static const speaker = 'Juju';

  /// O mês de relance, igual ao do Início: a sobra de outubro.
  static String get overline =>
      'Sobram ${BrlFormatter.format(HomeNumbers.leftover)} neste mês';

  @override
  Widget build(BuildContext context) {
    return CajuiScreen(
      title: 'Juju',
      overline: overline,
      trailing: ScreenTools(readOnly: readOnly),
      controller: controller,
      footer: footer,
      children: children,
    );
  }
}
