import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/depth/depth_notes.dart';

/// O efeito ao vivo e, ao lado, as regras dele — alinhadas pelo alto, para
/// a primeira regra ficar na altura em que o olho entra no palco. Em tela
/// estreita, as regras descem para baixo do palco.
class DepthShowcase extends StatelessWidget {
  /// Mostra [stage] com as regras [notes].
  const new({required this.stage, required this.notes, super.key});

  /// O efeito, rodando.
  final Widget stage;

  /// As regras: o que observar e por quê.
  final List<(String, String)> notes;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: CajuiSpacing.block,
      runSpacing: CajuiSpacing.xxl,
      children: [
        stage,
        Padding(
          padding: const EdgeInsets.only(top: CajuiSpacing.lg),
          child: DepthNotes(notes: notes),
        ),
      ],
    );
  }
}
