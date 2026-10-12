import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/home/home_numbers.dart';
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
  static String get _answer {
    String brl(int cents) => BrlFormatter.format(cents);
    return 'Dá, sim. Sobram ${brl(HomeNumbers.leftover)} neste mês, e a '
        'pizza de ${brl(5800)} deixa ${brl(HomeNumbers.leftover - 5800)}. A '
        'conta de luz vence na quinta, mas já está contada no que sai.';
  }

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
            CajuiChatBubble(
              _answer,
              key: ValueKey(_run),
              streamed: true,
              speaker: 'Juju',
            ),
            _again(),
          ],
        ),
      ),
    );
  }

  Widget _again() => Align(
    alignment: Alignment.centerLeft,
    child: CajuiButton(
      label: 'Responder de novo',
      size: CajuiButtonSize.compact,
      variant: CajuiButtonVariant.ghost,
      onPressed: () => setState(() => _run++),
    ),
  );
}
