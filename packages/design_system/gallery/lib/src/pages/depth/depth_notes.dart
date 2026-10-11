import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// As regras de um efeito, uma por linha, ao lado do palco: quem revisa lê
/// o que deve ver, e confere vendo.
class DepthNotes extends StatelessWidget {
  /// Cria a lista com [notes], cada uma um par de título e explicação.
  const new({required this.notes, super.key});

  /// As regras: o que observar e por quê.
  final List<(String, String)> notes;

  /// A coluna não passa disto: linha comprida cansa a leitura.
  static const double _maxWidth = 420;

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _maxWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (title, body) in notes) _note(theme, title, body),
        ],
      ),
    );
  }

  Widget _note(CajuiThemeData theme, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: CajuiSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.typography.label.copyWith(
              color: theme.colors.text.primary,
            ),
          ),
          const SizedBox(height: CajuiSpacing.xxs),
          Text(
            body,
            style: theme.typography.caption.copyWith(
              color: theme.colors.text.muted,
            ),
          ),
        ],
      ),
    );
  }
}
