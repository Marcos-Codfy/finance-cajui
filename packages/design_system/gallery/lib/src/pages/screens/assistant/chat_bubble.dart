import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Uma fala da conversa com o assistente.
///
/// Quem fala se distingue pelo lado, pela cor e pelo nome lido pelo leitor de
/// tela — nunca só pela cor.
class ChatBubble extends StatelessWidget {
  /// Cria a fala [text]. Com [fromUser], é de quem pergunta.
  const new(this.text, {this.fromUser = false, this.thinking = false, super.key});

  /// O que foi dito.
  final String text;

  /// A fala é de quem usa o app, e não do assistente.
  final bool fromUser;

  /// O assistente ainda está respondendo: três pontos no lugar do texto.
  final bool thinking;

  static const double _maxWidth = 290;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final colors = theme.colors;
    return Semantics(
      label: fromUser ? 'Você: $text' : 'Cajui: $text',
      excludeSemantics: true,
      child: Align(
        alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          margin: const EdgeInsets.only(bottom: CajuiSpacing.md),
          padding: const EdgeInsets.all(CajuiSpacing.md),
          decoration: BoxDecoration(
            color: fromUser ? colors.action.secondary : colors.surface.elevated,
            borderRadius: const BorderRadius.all(CajuiRadius.md),
            border: Border.all(color: colors.border.subtle),
          ),
          child: _content(theme),
        ),
      ),
    );
  }

  Widget _content(CajuiThemeData theme) {
    if (thinking) {
      return CajuiLoadingDots(
        color: theme.colors.text.muted,
        semanticLabel: 'Cajui está respondendo',
      );
    }
    return Text(
      text,
      style: theme.typography.body.copyWith(color: theme.colors.text.primary),
    );
  }
}
