import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/shared/phone_frame.dart';
import 'package:gallery/src/pages/screens/shared/screen_variant.dart';
import 'package:gallery/src/shell/gallery_page.dart';

/// A página de uma tela de estado: o seletor de estados e o aparelho.
///
/// Todas as telas usam esta mesma página, para que conferir um estado seja
/// sempre o mesmo gesto: escolher no seletor, olhar o aparelho, ler a nota.
class ScreenStatePage extends StatefulWidget {
  /// Cria a página da tela [title] com os estados [variants].
  const new({
    required this.title,
    required this.lead,
    required this.variants,
    super.key,
  });

  /// O nome da tela.
  final String title;

  /// O papel da tela no app.
  final String lead;

  /// Os estados, na ordem do seletor.
  final List<ScreenVariant> variants;

  @override
  State<ScreenStatePage> createState() => _ScreenStatePageState();
}

class _ScreenStatePageState extends State<ScreenStatePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final variant = widget.variants[_index];
    return GalleryPage(
      title: widget.title,
      lead: widget.lead,
      sections: [
        _selector(),
        const SizedBox(height: CajuiSpacing.lg),
        _note(context, variant),
        const SizedBox(height: CajuiSpacing.xl),
        PhoneFrame(
          child: KeyedSubtree(
            key: ValueKey(_index),
            child: Builder(builder: variant.builder),
          ),
        ),
      ],
    );
  }

  Widget _selector() {
    return Wrap(
      spacing: CajuiSpacing.sm,
      runSpacing: CajuiSpacing.sm,
      children: [
        for (final (index, variant) in widget.variants.indexed)
          CajuiChip(
            label: variant.label,
            selected: index == _index,
            onSelected: (_) => setState(() => _index = index),
          ),
      ],
    );
  }

  Widget _note(BuildContext context, ScreenVariant variant) {
    final theme = CajuiTheme.of(context);
    return Text(
      '${_index + 1} de ${widget.variants.length} · ${variant.note}',
      style: theme.typography.caption.copyWith(color: theme.colors.text.muted),
    );
  }
}
