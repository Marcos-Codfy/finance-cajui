import 'package:design_system/src/components/button/cajui_button_size.dart';
import 'package:design_system/src/components/button/cajui_button_tokens.dart';
import 'package:design_system/src/components/button/cajui_button_variant.dart';
import 'package:design_system/src/components/feedback/cajui_loading_dots.dart';
import 'package:design_system/src/icons/cajui_icon.dart';
import 'package:design_system/src/icons/cajui_icon_data.dart';
import 'package:design_system/src/interaction/cajui_pressable.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_durations.dart';
import 'package:design_system/src/tokens/primitives/cajui_radius.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// O botão do Cajui.
///
/// O rótulo segue o guia de voz: verbo no infinitivo, no máximo três palavras,
/// dizendo o que acontece — "Lançar", "Ver os ajustes", "Tirar outra foto".
///
/// Estados: repouso, sob o cursor, com foco, pressionado, desabilitado
/// (`onPressed` nulo) e carregando ([loading]).
class CajuiButton extends StatelessWidget {
  /// Cria um botão com o rótulo [label].
  const new({
    required this.label,
    required this.onPressed,
    this.variant = CajuiButtonVariant.primary,
    this.size = CajuiButtonSize.regular,
    this.icon,
    this.loading = false,
    this.expand = false,
    super.key,
  });

  /// O texto do botão.
  final String label;

  /// O que acontece ao ativar. `null` desabilita.
  final VoidCallback? onPressed;

  /// O peso do botão na tela.
  final CajuiButtonVariant variant;

  /// O tamanho do desenho.
  final CajuiButtonSize size;

  /// Ícone decorativo antes do rótulo.
  final CajuiIconData? icon;

  /// Carregando: mantém a largura, troca o rótulo pelos pontos e não dispara
  /// de novo.
  final bool loading;

  /// Se ocupa toda a largura disponível.
  final bool expand;

  static const _radius = BorderRadius.all(CajuiRadius.lg);

  @override
  Widget build(BuildContext context) {
    return CajuiPressable(
      onPressed: onPressed,
      busy: loading,
      radius: _radius,
      semanticLabel: loading ? '$label, aguarde' : label,
      builder: _surface,
    );
  }

  Widget _surface(BuildContext context, Set<WidgetState> states) {
    final theme = CajuiTheme.of(context);
    final tokens = CajuiButtonTokens.resolve(theme.colors, variant, states);
    return AnimatedContainer(
      duration: CajuiDurations.fast,
      height: size.height,
      width: expand ? double.infinity : null,
      padding: EdgeInsets.symmetric(horizontal: size.horizontalPadding),
      decoration: BoxDecoration(
        color: tokens.background,
        borderRadius: _radius,
      ),
      child: DefaultTextStyle.merge(
        style: _labelStyle(context).copyWith(color: tokens.foreground),
        child: _content(tokens.foreground),
      ),
    );
  }

  TextStyle _labelStyle(BuildContext context) {
    final typography = CajuiTheme.of(context).typography;
    return size == CajuiButtonSize.regular
        ? typography.bodyStrong
        : typography.label.copyWith(fontWeight: FontWeight.w600);
  }

  /// O rótulo continua ocupando espaço quando carregando, para o botão não
  /// mudar de largura debaixo do dedo.
  Widget _content(Color foreground) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Visibility.maintain(visible: !loading, child: _labelRow()),
        if (loading) CajuiLoadingDots(color: foreground, semanticLabel: ''),
      ],
    );
  }

  Widget _labelRow() {
    final leading = icon;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[
          CajuiIcon(leading, size: 20),
          const SizedBox(width: CajuiSpacing.sm),
        ],
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}
