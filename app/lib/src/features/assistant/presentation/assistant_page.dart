import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// A conversa com o assistente.
///
/// A conversa chega com a feature do assistente. A tela não finge um chat:
/// diz o que vai existir ali e que nada do que já foi lançado se perde.
class AssistantPage extends StatelessWidget {
  /// Cria a tela do assistente.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const CajuiScreen(
      title: 'Assistente',
      children: [
        CajuiEmptyState(
          title: 'A conversa entra aqui',
          message:
              'Perguntas como "quanto ainda posso gastar nesta semana?" '
              'serão respondidas com os seus números. O que você lança '
              'desde já fica guardado para isso.',
        ),
      ],
    );
  }
}
