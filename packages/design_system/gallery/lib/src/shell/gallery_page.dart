import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// A moldura de toda página da gallery: título, uma frase que diz para que a
/// página serve, e as seções, numa coluna rolável de largura confortável.
class GalleryPage extends StatelessWidget {
  /// Cria a página com [title], a frase [lead] e as [sections].
  const new({
    required this.title,
    required this.lead,
    required this.sections,
    super.key,
  });

  /// O título da página.
  final String title;

  /// Para que a página serve, em uma ou duas frases.
  final String lead;

  /// As seções, de cima para baixo.
  final List<Widget> sections;

  /// Largura máxima do conteúdo: além disso, a linha de texto fica longa
  /// demais para ler.
  static const double _maxWidth = 960;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: CajuiSpacing.xxl,
        vertical: CajuiSpacing.section,
      ),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [..._header(context), ...sections],
          ),
        ),
      ),
    );
  }

  List<Widget> _header(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return [
      Semantics(
        header: true,
        child: Text(
          title,
          style: theme.typography.displayMedium.copyWith(
            color: theme.colors.text.primary,
          ),
        ),
      ),
      const SizedBox(height: CajuiSpacing.sm),
      Text(
        lead,
        style: theme.typography.body.copyWith(color: theme.colors.text.muted),
      ),
      const SizedBox(height: CajuiSpacing.section),
    ];
  }
}
