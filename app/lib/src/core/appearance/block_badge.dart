import 'package:cajui/src/core/appearance/block_look.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// O ícone do grupo, na cor dele, para o começo de uma linha.
class BlockBadge extends StatelessWidget {
  /// Cria o ícone do grupo [block].
  const new(this.block, {super.key});

  /// O grupo.
  final Block block;

  @override
  Widget build(BuildContext context) => CajuiIcon(
    BlockLook.iconOf(block),
    size: 20,
    color: BlockLook.colorOf(block, CajuiTheme.of(context).colors),
  );
}
