import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A câmera e a galeria no alto da tela: fotografar ou escolher um
/// comprovante é o caminho mais comum de um lançamento, e fica à mão no
/// Início e na conversa com a Juju.
///
/// Na consulta pela web não há captura, e os botões nem aparecem.
class CaptureTools extends ConsumerWidget {
  /// Cria os botões, e mais [extra] depois deles.
  const new({required this.readOnly, this.extra = const [], super.key});

  /// Se a tela só consulta: sem captura.
  final bool readOnly;

  /// Os botões que vêm depois, como os ajustes.
  final List<Widget> extra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capture = ref.watch(captureServiceProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!readOnly && capture.canPhotograph)
          CajuiIconButton(
            icon: CajuiIconData.camera,
            semanticLabel: 'Fotografar comprovante',
            onPressed: () => _open(context, capture.photograph),
          ),
        if (!readOnly && capture.canPickFiles)
          CajuiIconButton(
            icon: CajuiIconData.image,
            semanticLabel: 'Escolher da galeria ou dos arquivos',
            onPressed: () => _open(context, capture.pickFromDevice),
          ),
        ...extra,
      ],
    );
  }

  /// Quem não conseguiu abrir a câmera ouve o aviso macio, e não nada.
  static Future<void> _open(
    BuildContext context,
    Future<bool> Function() open,
  ) async {
    final feedback = CajuiFeedbackScope.of(context);
    if (!await open()) feedback.notice();
  }
}
