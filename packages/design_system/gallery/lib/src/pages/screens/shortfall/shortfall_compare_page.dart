import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/app/gallery_scope.dart';
import 'package:gallery/src/pages/screens/closing/closing_page.dart';
import 'package:gallery/src/pages/screens/shared/phone_frame.dart';
import 'package:gallery/src/shell/gallery_page.dart';
import 'package:gallery/src/shell/gallery_section.dart';

/// A mesma tela de falta do mês nas duas versões em avaliação, lado a lado.
///
/// É uma decisão de produto, e não de gosto: a tela que dá a má notícia
/// define se a pessoa volta ao app no mês seguinte. Por isso as duas versões
/// aparecem iguais em tudo, menos no token `shortfall`.
class ShortfallComparePage extends StatelessWidget {
  /// Cria a página de comparação.
  const new({super.key});

  static const Map<ShortfallStyle, (String, String)> _versions = {
    ShortfallStyle.calm: (
      'Barro',
      'Tom de terra, o mesmo peso visual da sobra. A ênfase vai para o que '
          'dá para fazer. Segue a decisão D-UX-22 da pesquisa: falta é fato '
          'e distância a percorrer, nunca bronca — quem se sente julgado '
          'para de olhar.',
    ),
    ShortfallStyle.alarm: (
      'Vermelho',
      'O padrão do mercado: negativo em vermelho. Leitura imediata para quem '
          'vem de banco e planilha, ao custo de soar como bronca.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    return GalleryPage(
      title: 'Falta do mês',
      lead:
          'Uma decisão em aberto: como o Cajui pinta o mês que não fechou. '
          'Só o token `shortfall` muda entre as duas telas — texto, '
          'tamanho e ordem são os mesmos. Vale conferir também no tema '
          'escuro.',
      sections: [
        Wrap(
          spacing: CajuiSpacing.section,
          runSpacing: CajuiSpacing.section,
          children: [
            for (final style in ShortfallStyle.values) _Version(style),
          ],
        ),
      ],
    );
  }
}

class _Version extends StatelessWidget {
  const new(this.style);

  final ShortfallStyle style;

  /// O tema em vigor, trocando só a versão da falta.
  CajuiThemeData _themed(CajuiThemeData base) {
    final light = base.colors.brightness == Brightness.light;
    return light
        ? CajuiThemeData.light(
            shortfallStyle: style,
            motionLevel: base.motionLevel,
          )
        : CajuiThemeData.dark(
            shortfallStyle: style,
            motionLevel: base.motionLevel,
          );
  }

  @override
  Widget build(BuildContext context) {
    final controller = GalleryScope.of(context);
    final theme = _themed(CajuiTheme.of(context));
    final (name, argument) = ShortfallComparePage._versions[style]!;
    final ratio = WcagContrast.ratio(
      theme.colors.shortfall,
      theme.colors.surface.elevated,
    );
    return SizedBox(
      width: 390,
      child: GallerySection(
        title: name,
        description:
            '$argument Contraste do número sobre o cartão: '
            '${ratio.toStringAsFixed(2)}:1.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CajuiChip(
              label: 'Usar na gallery inteira',
              selected: controller.shortfallStyle == style,
              onSelected: (_) => controller.useShortfallStyle(style),
            ),
            const SizedBox(height: CajuiSpacing.lg),
            _preview(theme),
          ],
        ),
      ),
    );
  }

  /// A tela de fechamento com falta, sob o tema desta versão.
  Widget _preview(CajuiThemeData theme) {
    return CajuiTheme(
      data: theme,
      child: PhoneFrame(
        child: Builder(builder: const ClosingPage().shortfall().builder),
      ),
    );
  }
}
