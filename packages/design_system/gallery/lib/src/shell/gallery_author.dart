import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

/// De quem é a gallery, e para onde ir depois dela.
///
/// O link circula sozinho — num currículo, numa mensagem —, e a página que
/// abre precisava dizer quem fez e levar ao resto do trabalho. O repositório
/// do Cajui ainda é privado: o link vai para o perfil, que é público.
class GalleryAuthor extends StatelessWidget {
  /// Cria o bloco do autor.
  const new({super.key});

  /// O nome, como no README e nos commits.
  static const name = 'Marcos Vinicius Muniz Arruda';

  /// O perfil público no GitHub.
  static final Uri profile = Uri.parse('https://github.com/Marcos-Codfy');

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Wrap(
      spacing: CajuiSpacing.lg,
      runSpacing: CajuiSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Especificação, design e código de $name, de Palmas (TO).',
          style: theme.typography.body.copyWith(color: theme.colors.text.muted),
        ),
        CajuiButton(
          label: 'Perfil no GitHub',
          variant: CajuiButtonVariant.secondary,
          size: CajuiButtonSize.compact,
          onPressed: () =>
              unawaited(launchUrl(profile, webOnlyWindowName: '_blank')),
        ),
      ],
    );
  }
}
