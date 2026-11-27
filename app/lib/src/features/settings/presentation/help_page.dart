import 'package:cajui/src/core/navigation/coordinator_access.dart';
import 'package:cajui/src/features/settings/presentation/help_topics.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// "Como o Cajui conta": o que é cada número do app, em poucas linhas
/// (27/11/2026, heurística de ajuda e documentação).
///
/// Cada assunto abre e fecha sozinho: quem chegou com uma dúvida lê só a
/// dela, sem rolar um manual.
class HelpPage extends StatelessWidget {
  /// Cria a tela de ajuda.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final muted = theme.typography.body.copyWith(
      color: theme.colors.text.muted,
    );
    return CajuiScreen(
      title: 'Como o Cajui conta',
      onBack: context.back,
      children: [
        Text(
          'O que é cada número do app. Os valores dos exemplos são '
          'inventados.',
          style: muted,
        ),
        const SizedBox(height: CajuiSpacing.lg),
        for (final topic in helpTopics)
          CajuiDisclosure(
            title: topic.title,
            children: [Text(topic.text, style: muted)],
          ),
      ],
    );
  }
}
