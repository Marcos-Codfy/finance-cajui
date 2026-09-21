import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// "Ver o que foi lido" (RN-735): o texto que o aparelho extraiu do
/// comprovante e, abaixo, esse mesmo texto **como sairia do aparelho** — com
/// os dados pessoais trocados por marcadores.
///
/// É a transparência do fluxo em uma tela: a pessoa vê o que o app enxergou,
/// inclusive texto que estava invisível no PDF, e o que ele esconde.
class ReadTextPage extends StatelessWidget {
  /// Cria a tela para o texto lido [text].
  const new({required this.text, super.key});

  /// O texto extraído, já limpo.
  final String text;

  /// Abre a tela.
  static Future<void> open(BuildContext context, String text) {
    return Navigator.of(context)
        .push<void>(CajuiPageRoute(builder: (_) => ReadTextPage(text: text)));
  }

  @override
  Widget build(BuildContext context) {
    return CajuiScreen(
      title: 'O que foi lido',
      onBack: Navigator.of(context).pop,
      children: [
        _section(
          context,
          'Lido no aparelho',
          'Fica só aqui. A imagem do comprovante nunca é enviada.',
          text,
        ),
        const SizedBox(height: CajuiSpacing.xl),
        _section(
          context,
          'Como sai do aparelho',
          'Só o texto, e com nome, CPF, conta e chave Pix mascarados.',
          PiiRedactor.redact(text),
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
        Text(title, style: theme.typography.title),
        const SizedBox(height: CajuiSpacing.xs),
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
