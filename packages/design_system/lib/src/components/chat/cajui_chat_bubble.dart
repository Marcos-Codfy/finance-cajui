import 'package:design_system/src/components/feedback/cajui_loading_dots.dart';
import 'package:design_system/src/components/streaming/cajui_streaming_text.dart';
import 'package:design_system/src/theme/cajui_theme.dart';
import 'package:design_system/src/theme/cajui_theme_data.dart';
import 'package:design_system/src/tokens/primitives/cajui_radius.dart';
import 'package:design_system/src/tokens/primitives/cajui_spacing.dart';
import 'package:flutter/widgets.dart';

/// Uma fala da conversa com o assistente.
///
/// Quem fala se distingue pelo lado, pela cor e pelo nome lido pelo leitor de
/// tela — nunca só pela cor.
class CajuiChatBubble extends StatelessWidget {
  /// Cria a fala [text]. Com [fromUser], é de quem pergunta.
  const new(
    this.text, {
    this.fromUser = false,
    this.thinking = false,
    this.streamed = false,
    super.key,
  });

  /// O que foi dito.
  final String text;

  /// A fala é de quem usa o app, e não do assistente.
  final bool fromUser;

  /// O assistente ainda está respondendo: três pontos no lugar do texto.
  final bool thinking;

  /// A resposta aparece palavra por palavra (`CajuiStreamingText`). Só vale
  /// para a fala do assistente, e só para a resposta que acabou de chegar:
  /// ao reabrir a conversa, o histórico aparece pronto.
  final bool streamed;

  static const double _maxWidth = 290;

  /// O que o leitor de tela diz. Na espera não há texto, então o balão diz
  /// o que está acontecendo — senão ele anunciaria um "Cajui:" vazio.
  String get _spokenLabel {
    if (thinking) return 'Cajui está respondendo';
    return fromUser ? 'Você: $text' : 'Cajui: $text';
  }

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final colors = theme.colors;
    return Semantics(
      label: _spokenLabel,
      // A espera é anunciada quando começa; a resposta, uma vez só, inteira.
      liveRegion: !fromUser,
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
    final style = theme.typography.body.copyWith(
      color: theme.colors.text.primary,
    );
    if (streamed && !fromUser) return CajuiStreamingText(text, style: style);
    return Text(text, style: style);
  }
}
