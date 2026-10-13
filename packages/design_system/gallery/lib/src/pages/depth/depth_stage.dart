import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/shared/phone_frame.dart';

/// O palco dos efeitos de profundidade: uma tela de celular de verdade, com
/// a própria rolagem.
///
/// Os efeitos dependem de onde o bloco está **na tela que rola** — sem uma
/// tela do tamanho de um aparelho, a borda que curva seria a da janela do
/// navegador. É a mesma moldura das telas do app (`PhoneFrame`): em tela
/// estreita, encolhe para caber.
class DepthStage extends StatelessWidget {
  /// Monta o palco em volta de [child].
  const new({required this.child, this.height = 620, super.key});

  /// A tela.
  final Widget child;

  /// A altura do palco. `null` deixa a tela do tamanho do conteúdo — para
  /// um bloco só, como o carrossel, que não rola.
  final double? height;

  @override
  Widget build(BuildContext context) =>
      PhoneFrame(height: height, child: child);
}
