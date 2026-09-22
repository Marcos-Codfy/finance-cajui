import 'package:cajui/src/features/receipts/presentation/understood_section.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// "Ver o que foi lido" (RN-735): o que o app entendeu do comprovante, o
/// texto que o aparelho extraiu e esse mesmo texto **como sairia do
/// aparelho** — com os dados pessoais trocados por marcadores.
///
/// A ordem é a da pergunta que a pessoa tem: primeiro *o que você entendeu
/// disso?*, e só depois o texto cru, que é longo e serve para conferir. O
/// texto cru vai arrumado em linhas (`ReceiptLayout`), porque cupom achatado
/// pelo OCR não se lê.
class ReadTextPage extends StatelessWidget {
  /// Cria a tela para o texto lido [text].
  const new({required this.text, this.proposal, super.key});

  /// O texto extraído, já limpo.
  final String text;

  /// O que as regras entenderam do texto. Sem isto, a tela mostra só o texto.
  final EntryProposal? proposal;

  /// Abre a tela.
  static Future<void> open(
    BuildContext context,
    String text, {
    EntryProposal? proposal,
  }) {
    return Navigator.of(context).push<void>(
      CajuiPageRoute(
        builder: (_) => ReadTextPage(text: text, proposal: proposal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final understood = proposal;
    return CajuiScreen(
      title: 'O que foi lido',
      onBack: Navigator.of(context).pop,
      children: [
        if (understood != null) ...UnderstoodSection.of(understood, text: text),
        _section(
          context,
          'O texto do comprovante',
          'Como o aparelho leu, linha por linha. Fica só aqui: a imagem '
              'nunca é enviada.',
          ReceiptLayout.readable(text),
        ),
        const SizedBox(height: CajuiSpacing.xl),
        _section(
          context,
          'Como sai do aparelho',
          'Só o texto, e com nome, CPF, conta e chave Pix mascarados.',
          ReceiptLayout.readable(PiiRedactor.redact(text)),
        ),
      ],
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    String explanation,
    String content,
  ) {
    final theme = CajuiTheme.of(context);
    final muted = theme.colors.text.muted;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CajuiSectionTitle(title),
        Text(
          explanation,
          style: theme.typography.caption.copyWith(color: muted),
        ),
        const SizedBox(height: CajuiSpacing.md),
        CajuiCard(
          sunken: true,
          child: Text(content, style: theme.typography.caption),
        ),
      ],
    );
  }
}
