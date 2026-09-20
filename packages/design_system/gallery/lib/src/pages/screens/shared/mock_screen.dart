import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// O esqueleto comum das telas de estado: título, conteúdo rolável e, se
/// houver, a área de ação presa embaixo — onde o polegar alcança.
class MockScreen extends StatelessWidget {
  /// Cria a tela [title] com o conteúdo [children].
  const new({
    required this.title,
    required this.children,
    this.overline,
    this.footer,
    super.key,
  });

  /// O título da tela.
  final String title;

  /// A linha miúda acima do título: o mês, a semana, o passo.
  final String? overline;

  /// O conteúdo, de cima para baixo.
  final List<Widget> children;

  /// As ações principais, presas ao pé da tela.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final foot = footer;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(CajuiSpacing.xl),
            children: [..._header(context), ...children],
          ),
        ),
        if (foot != null)
          Padding(padding: const EdgeInsets.all(CajuiSpacing.xl), child: foot),
      ],
    );
  }

  List<Widget> _header(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final above = overline;
    return [
      const SizedBox(height: CajuiSpacing.lg),
      if (above != null)
        Text(
          above.toUpperCase(),
          style: theme.typography.overline.copyWith(
            color: theme.colors.text.faint,
          ),
        ),
      Text(
        title,
        style: theme.typography.headline.copyWith(
          color: theme.colors.text.primary,
        ),
      ),
      const SizedBox(height: CajuiSpacing.xl),
    ];
  }
}
