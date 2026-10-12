import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// Os botões do alto do Início e da Juju, como no app: a câmera e a
/// galeria — fotografar ou escolher um comprovante é o caminho mais comum de
/// um lançamento — e, no Início, os ajustes.
///
/// Na consulta pela web não há captura, e a câmera e a galeria nem
/// aparecem: só leitura, sem botão que não leva a nada.
class ScreenTools extends StatelessWidget {
  /// Cria os botões; [readOnly] tira a captura, [settings] põe os ajustes.
  const new({this.readOnly = false, this.settings = false, super.key});

  /// A tela só consulta: sem câmera nem galeria.
  final bool readOnly;

  /// Se os ajustes vêm depois da captura, como no Início.
  final bool settings;

  void _nothing() {}

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!readOnly) ...[
          CajuiIconButton(
            icon: CajuiIconData.camera,
            semanticLabel: 'Fotografar comprovante',
            onPressed: _nothing,
          ),
          CajuiIconButton(
            icon: CajuiIconData.image,
            semanticLabel: 'Escolher da galeria ou dos arquivos',
            onPressed: _nothing,
          ),
        ],
        if (settings)
          CajuiIconButton(
            icon: CajuiIconData.sliders,
            semanticLabel: 'Ajustes',
            onPressed: _nothing,
          ),
      ],
    );
  }
}
