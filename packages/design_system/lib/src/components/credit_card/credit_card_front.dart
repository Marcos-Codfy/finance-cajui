import 'package:design_system/src/components/credit_card/card_sheen.dart';
import 'package:design_system/src/icons/cajui_icon.dart';
import 'package:design_system/src/icons/cajui_icon_data.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/theme/cajui_theme_data.dart';
import 'package:design_system/src/tokens/primitives/cajui_radius.dart';
import 'package:design_system/src/tokens/primitives/cajui_shadows.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// A frente do cartão: nome, chip e os dias de fechamento e vencimento.
///
/// O fundo é o gradiente de ação, e o texto, o de cima de ação: um par que o
/// teste de contraste já mede, inclusive com o brilho por baixo.
class CreditCardFront extends StatelessWidget {
  /// Cria a frente do cartão [name], com a linha [detail].
  const new({
    required this.name,
    required this.detail,
    required this.light,
    super.key,
  });

  /// O nome do cartão.
  final String name;

  /// A linha da frente, no lugar do número que o Cajui não guarda.
  final String detail;

  /// Onde a luz bate.
  final Alignment light;

  /// O raio de canto dos dois lados do cartão.
  static const radius = BorderRadius.all(CajuiRadius.lg);

  /// A sombra dos dois lados: o cartão flutua um pouco acima da tela. No
  /// escuro não há sombra — lá a elevação é dita pela cor.
  static List<BoxShadow> shadowOf(Brightness brightness) =>
      brightness == Brightness.light
      ? CajuiShadows.floating
      : CajuiShadows.none;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final colors = theme.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: shadowOf(colors.brightness),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.action.primary, colors.action.primaryPressed],
        ),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(child: CardSheen(light: light)),
            Padding(
              padding: const EdgeInsets.all(CajuiSpacing.xl),
              child: _content(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(CajuiThemeData theme) {
    final ink = theme.colors.text.onAction;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _title(theme, ink),
        const SizedBox(height: CajuiSpacing.md),
        const _Chip(),
        const SizedBox(height: CajuiSpacing.md),
        _number(theme, ink),
      ],
    );
  }

  Widget _title(CajuiThemeData theme, Color ink) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.title.copyWith(color: ink),
          ),
        ),
        CajuiIcon(CajuiIconData.card, color: ink),
      ],
    );
  }

  /// Os dias do cartão e o convite para virar: a frente diz que o verso
  /// existe, senão ninguém descobre que o cartão vira.
  Widget _number(CajuiThemeData theme, Color ink) {
    return Wrap(
      spacing: CajuiSpacing.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(detail, style: theme.typography.body.copyWith(color: ink)),
        Text(
          'Toque para ver o limite',
          style: theme.typography.caption.copyWith(color: ink),
        ),
      ],
    );
  }
}

/// O chip dourado: só desenho, para o cartão ler como cartão de relance.
class _Chip extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final brand = CajuiTheme.of(context).colors.brand;
    return SizedBox(
      width: 40,
      height: 30,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(CajuiRadius.xs),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(brand.gold, brand.sheen, 0.35)!, brand.gold],
          ),
        ),
      ),
    );
  }
}
