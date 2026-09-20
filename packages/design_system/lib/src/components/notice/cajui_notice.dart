import 'package:design_system/src/components/button/cajui_button.dart';
import 'package:design_system/src/components/button/cajui_button_size.dart';
import 'package:design_system/src/components/button/cajui_button_variant.dart';
import 'package:design_system/src/components/button/cajui_icon_button.dart';
import 'package:design_system/src/components/notice/cajui_notice_action.dart';
import 'package:design_system/src/components/notice/cajui_notice_intent.dart';
import 'package:design_system/src/icons/cajui_icon.dart';
import 'package:design_system/src/icons/cajui_icon_data.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/tokens/primitives/cajui_radius.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// O aviso persistente: o veículo de todo erro e de todo estado que o
/// usuário precisa saber.
///
/// A estrutura **é** a fórmula do guia de voz, e por isso os três campos são
/// separados: [what] diz o que aconteceu, [meaning] diz o que isso significa,
/// e as ações dizem o que dá para fazer agora. Não existe aviso do Cajui sem
/// o primeiro, e erro sem pelo menos uma saída é defeito de especificação.
///
/// Fica na tela até o usuário agir ou fechar: aviso que some sozinho é
/// barreira de acessibilidade (RNF-A11Y-13).
class CajuiNotice extends StatelessWidget {
  /// Cria um aviso.
  const new({
    required this.what,
    this.meaning,
    this.intent = CajuiNoticeIntent.attention,
    this.primaryAction,
    this.secondaryAction,
    this.onDismiss,
    super.key,
  });

  /// O que aconteceu: "Não consegui ler este comprovante."
  final String what;

  /// O que isso significa: "O arquivo está guardado; nada foi perdido."
  final String? meaning;

  /// A intenção do aviso.
  final CajuiNoticeIntent intent;

  /// A saída principal: "Tirar outra foto".
  final CajuiNoticeAction? primaryAction;

  /// A saída alternativa: "Digitar os dados".
  final CajuiNoticeAction? secondaryAction;

  /// Se presente, mostra o botão de fechar.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = CajuiTheme.of(context).colors;
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: intent.background(colors),
          borderRadius: const BorderRadius.all(CajuiRadius.lg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(CajuiSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CajuiIcon(intent.icon, color: intent.foreground(colors)),
              const SizedBox(width: CajuiSpacing.md),
              Expanded(child: _body(context)),
              if (onDismiss != null) _dismiss(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final explanation = meaning;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          what,
          style: theme.typography.bodyStrong.copyWith(
            color: theme.colors.text.primary,
          ),
        ),
        if (explanation != null) ...[
          const SizedBox(height: CajuiSpacing.xs),
          Text(
            explanation,
            style: theme.typography.body.copyWith(
              color: theme.colors.text.muted,
            ),
          ),
        ],
        if (primaryAction != null || secondaryAction != null) _actions(),
      ],
    );
  }

  Widget _actions() {
    final main = primaryAction;
    final other = secondaryAction;
    return Padding(
      padding: const EdgeInsets.only(top: CajuiSpacing.md),
      child: Wrap(
        spacing: CajuiSpacing.sm,
        children: [
          if (main != null)
            CajuiButton(
              label: main.label,
              onPressed: main.onPressed,
              size: CajuiButtonSize.compact,
              variant: CajuiButtonVariant.secondary,
            ),
          if (other != null)
            CajuiButton(
              label: other.label,
              onPressed: other.onPressed,
              size: CajuiButtonSize.compact,
              variant: CajuiButtonVariant.ghost,
            ),
        ],
      ),
    );
  }

  Widget _dismiss() {
    return CajuiIconButton(
      icon: CajuiIconData.close,
      semanticLabel: 'Fechar aviso',
      onPressed: onDismiss,
    );
  }
}
