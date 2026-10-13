import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/shell/gallery_section.dart';

/// Uma regra do Cajui em par: o jeito certo e o que evitar, lado a lado,
/// com o porquê numa frase.
///
/// O "evite" é desenhado de propósito com o erro — o vermelho, a palavra de
/// bronca, a soma que mistura moedas —: é o que o app nunca faz, e só
/// aparece aqui, marcado como tal.
class DoDontPair extends StatelessWidget {
  /// Cria o par da regra [title], explicada por [why].
  const new({
    required this.title,
    required this.why,
    required this.good,
    required this.bad,
    super.key,
  });

  /// A regra, numa linha: "A falta é fato, não bronca".
  final String title;

  /// O porquê.
  final String why;

  /// O jeito certo.
  final Widget good;

  /// O que evitar.
  final Widget bad;

  /// Largura de cada lado: dois cabem lado a lado na coluna da página, e no
  /// celular um vai embaixo do outro.
  static const double _side = 340;

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: title,
      description: why,
      child: Wrap(
        spacing: CajuiSpacing.lg,
        runSpacing: CajuiSpacing.lg,
        children: [
          SizedBox(
            width: _side,
            child: _Side(good: true, child: good),
          ),
          SizedBox(
            width: _side,
            child: _Side(good: false, child: bad),
          ),
        ],
      ),
    );
  }
}

/// Um lado do par, com a marca escrita em cima: "Faça" ou "Evite". A marca
/// tem ícone e palavra, e não só cor.
class _Side extends StatelessWidget {
  const new({required this.good, required this.child});

  final bool good;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final tone = good
        ? theme.colors.intent.positive
        : theme.colors.intent.danger;
    return CajuiCard(
      sunken: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CajuiSpacing.md,
        children: [
          Row(
            spacing: CajuiSpacing.xs,
            children: [
              CajuiIcon(
                good ? CajuiIconData.check : CajuiIconData.close,
                color: tone,
              ),
              Text(
                good ? 'Faça' : 'Evite',
                style: theme.typography.label.copyWith(color: tone),
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}
