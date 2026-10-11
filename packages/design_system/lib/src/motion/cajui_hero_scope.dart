import 'package:flutter/widgets.dart';

/// Liga o voo de elementos entre telas num app sem Material.
///
/// O `MaterialApp` traz isso escondido; o `WidgetsApp`, que o Cajui usa para
/// não ter tema de terceiros por baixo, não traz — e sem ele um
/// `CajuiHeroNumber` simplesmente não voa, sem erro nenhum. Fica acima do
/// navegador (no `builder` do app); o `CajuiAppSurface` já o inclui.
class CajuiHeroScope extends StatefulWidget {
  /// Disponibiliza o controlador de voo para o navegador dentro de [child].
  const new({required this.child, super.key});

  /// O app, com o navegador dentro.
  final Widget child;

  @override
  State<CajuiHeroScope> createState() => _CajuiHeroScopeState();
}

class _CajuiHeroScopeState extends State<CajuiHeroScope> {
  /// Um controlador só, para a vida inteira do app: o navegador se registra
  /// nele, e trocar de controlador no meio de um voo o perderia.
  final _controller = HeroController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      HeroControllerScope(controller: _controller, child: widget.child);
}
