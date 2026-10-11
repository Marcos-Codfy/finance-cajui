import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/shell/gallery_section.dart';

/// A resposta do assistente aparecendo palavra por palavra.
class StreamingSection extends StatefulWidget {
  /// Cria a seção.
  const new({super.key});

  @override
  State<StreamingSection> createState() => _StreamingSectionState();
}

class _StreamingSectionState extends State<StreamingSection> {
  /// Uma conversa fictícia, no tom do guia de voz.
  static const _question = 'Dá para pedir uma pizza hoje?';
  static const _answer =
      r'Dá, sim. Ainda cabem R$ 212,00 até domingo, e a pizza de R$ 58,00 '
      r'deixa R$ 154,00 para o resto da semana. A conta de luz vence na '
      'quinta, mas já está separada.';

  int _run = 0;

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Resposta palavra por palavra',
      description:
          'As palavras aparecem num esmaecer curto, e o balão já nasce do '
          'tamanho final — nada pula de linha. Um toque no texto mostra tudo. '
          'Resposta longa nunca leva mais de 4 s; no movimento reduzido, '
          'aparece inteira. O leitor de tela ouve a resposta inteira, uma vez.',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CajuiChatBubble(_question, fromUser: true),
            CajuiChatBubble(_answer, key: ValueKey(_run), streamed: true),
            Align(
              alignment: Alignment.centerLeft,
              child: CajuiButton(
                label: 'Responder de novo',
                size: CajuiButtonSize.compact,
                variant: CajuiButtonVariant.ghost,
                onPressed: () => setState(() => _run++),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
