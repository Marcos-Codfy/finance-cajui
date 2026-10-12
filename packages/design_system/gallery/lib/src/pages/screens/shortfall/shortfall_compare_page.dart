import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/closing/closing_page.dart';
import 'package:gallery/src/pages/screens/shared/phone_frame.dart';
import 'package:gallery/src/shell/gallery_page.dart';

/// A mesma tela de falta do mês nas duas versões, lado a lado: a escolhida
/// (barro) e a que ficou de fora (vermelho).
///
/// É uma decisão de produto, e não de gosto: a tela que dá a má notícia
/// define se a pessoa volta ao app no mês seguinte. As duas versões
/// aparecem iguais em tudo, menos no token `shortfall`. O barro foi aprovado
/// com o design system, na Fase 3; a página mostra o porquê.
class ShortfallComparePage extends StatelessWidget {
  /// Cria a página de comparação.
  const new({super.key});

  /// As explicações das duas colunas e os aparelhos ficam em fileiras
  /// separadas: numa coluna só por versão, a explicação mais longa empurrava
  /// um aparelho para baixo, e os dois não começavam na mesma altura — numa
  /// página feita para comparar.
  static const double _gap = CajuiSpacing.section;

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Cor da falta',
      lead:
          'Decisão tomada: o dinheiro que falta no mês é barro, e não '
          'vermelho. As duas telas são iguais em texto, tamanho e ordem — só '
          'a cor muda. Para ver a gallery inteira na outra versão, troque em '
          'Ajustes.',
      sections: [
        LayoutBuilder(
          builder: (context, constraints) {
            final sideBySide =
                constraints.maxWidth >= 2 * PhoneFrame.width + _gap;
            return sideBySide ? _sideBySide() : _stacked();
          },
        ),
      ],
    );
  }

  Widget _sideBySide() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: CajuiSpacing.lg,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: _gap,
        children: [
          for (final style in ShortfallStyle.values)
            SizedBox(width: PhoneFrame.width, child: _Why(style)),
        ],
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: _gap,
        children: [for (final style in ShortfallStyle.values) _Preview(style)],
      ),
    ],
  );

  Widget _stacked() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: _gap,
    children: [
      for (final style in ShortfallStyle.values)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: CajuiSpacing.lg,
          children: [_Why(style), _Preview(style)],
        ),
    ],
  );
}

/// O tema em vigor, trocando só a versão da falta.
CajuiThemeData _themed(CajuiThemeData base, ShortfallStyle style) =>
    base.colors.brightness == Brightness.light
    ? CajuiThemeData.light(shortfallStyle: style, motionLevel: base.motionLevel)
    : CajuiThemeData.dark(shortfallStyle: style, motionLevel: base.motionLevel);

/// O nome da versão, o argumento e o contraste medido do número.
class _Why extends StatelessWidget {
  const new(this.style);

  final ShortfallStyle style;

  static const Map<ShortfallStyle, (String, String)> _versions = {
    ShortfallStyle.calm: (
      'Barro · a escolhida',
      'Tom de terra, o mesmo peso visual da sobra. A ênfase vai para o que '
          'dá para fazer: falta é fato e distância a percorrer, nunca '
          'bronca — quem se sente julgado para de olhar.',
    ),
    ShortfallStyle.alarm: (
      'Vermelho · a que ficou de fora',
      'O padrão do mercado: negativo em vermelho. Leitura imediata para quem '
          'vem de banco e planilha, ao custo de soar como bronca. O vermelho '
          'ficou para o que é erro de verdade.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final base = CajuiTheme.of(context);
    final colors = _themed(base, style).colors;
    final ratio = WcagContrast.ratio(colors.shortfall, colors.surface.elevated);
    final (name, argument) = _versions[style]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: CajuiSpacing.xs,
      children: [
        Text(
          name,
          style: base.typography.title.copyWith(
            color: base.colors.text.primary,
          ),
        ),
        Text(
          '$argument Contraste do número sobre o cartão: '
          '${ratio.toStringAsFixed(2)}:1.',
          style: base.typography.caption.copyWith(
            color: base.colors.text.muted,
          ),
        ),
      ],
    );
  }
}

/// A tela de fechamento com falta, sob o tema desta versão.
class _Preview extends StatelessWidget {
  const new(this.style);

  final ShortfallStyle style;

  @override
  Widget build(BuildContext context) {
    return CajuiTheme(
      data: _themed(CajuiTheme.of(context), style),
      child: PhoneFrame(
        child: Builder(builder: ClosingPage.shortfall().builder),
      ),
    );
  }
}
