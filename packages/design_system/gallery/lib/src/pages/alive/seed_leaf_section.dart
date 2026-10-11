import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/shell/gallery_section.dart';

/// Lançar e desfazer de verdade: o lançamento entra na lista com a semente
/// caindo e sai com a folha, sempre com o pulso leve.
class SeedLeafSection extends StatefulWidget {
  /// Cria a seção.
  const new({super.key});

  @override
  State<SeedLeafSection> createState() => _SeedLeafSectionState();
}

class _SeedLeafSectionState extends State<SeedLeafSection> {
  /// Lançamentos fictícios, na ordem em que entram.
  static const _queue = [
    ('Padaria', 'Débito', 1250),
    ('Mercado', 'Vale alimentação', 8790),
    ('Farmácia', 'Pix', 3415),
    ('Corrida de app', 'Crédito · Cartão Ipê', 2280),
  ];

  final List<(String, String, int)> _entries = [];

  void _add() {
    final next = _queue[_entries.length % _queue.length];
    setState(() => _entries.insert(0, next));
    CajuiFeedbackScope.of(context).entrySaved();
  }

  void _undo() {
    if (_entries.isEmpty) return;
    setState(() => _entries.removeAt(0));
    CajuiFeedbackScope.of(context).undone();
  }

  @override
  Widget build(BuildContext context) {
    return GallerySection(
      title: 'Semente e folha',
      description:
          'Lançar toca uma semente caindo na cuia; desfazer, uma folha que '
          'vai e volta. Os dois vêm com o pulso leve de tecla, e o som nasce '
          'desligado — ligue no chip "Som" para ouvir. Os dois sons estão '
          'também na mesa de som.',
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buttons(),
            const SizedBox(height: CajuiSpacing.md),
            for (final (index, entry) in _entries.indexed) _row(index, entry),
          ],
        ),
      ),
    );
  }

  /// A chave conta de baixo para cima: o item novo é o único que entra, e os
  /// de baixo não repetem a entrada.
  Widget _row(int index, (String, String, int) entry) {
    final (what, paidWith, cents) = entry;
    return CajuiEntrance(
      key: ValueKey(_entries.length - index),
      child: CajuiListRow(
        title: what,
        subtitle: paidWith,
        trailing: CajuiAmountText(cents),
      ),
    );
  }

  /// Os botões ficam sem o som de toque: a semente e a folha já são a
  /// resposta, e o toque por cima as abafaria.
  Widget _buttons() {
    return CajuiFeedbackScope(
      feedback: const SilentFeedback(),
      child: Wrap(
        spacing: CajuiSpacing.sm,
        runSpacing: CajuiSpacing.sm,
        children: [
          CajuiButton(
            label: 'Lançar',
            icon: CajuiIconData.plus,
            size: CajuiButtonSize.compact,
            onPressed: _add,
          ),
          CajuiButton(
            label: 'Desfazer',
            size: CajuiButtonSize.compact,
            variant: CajuiButtonVariant.secondary,
            onPressed: _entries.isEmpty ? null : _undo,
          ),
        ],
      ),
    );
  }
}
