import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// O campo de pergunta da Juju, com o microfone e o botão de enviar ao lado,
/// como no app. Enquanto a resposta não chega, tudo espera: uma pergunta
/// por vez.
class JujuComposer extends StatelessWidget {
  /// Cria o campo; com [enabled] falso, ele espera a resposta.
  const new({this.enabled = true, super.key});

  /// Se dá para perguntar agora.
  final bool enabled;

  void _nothing() {}

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: CajuiTextField(
            label: 'Sua pergunta',
            hint: 'Quanto sobra neste mês?',
            enabled: enabled,
          ),
        ),
        const SizedBox(width: CajuiSpacing.sm),
        CajuiIconButton(
          icon: CajuiIconData.microphone,
          semanticLabel: 'Ditar a pergunta',
          onPressed: enabled ? _nothing : null,
        ),
        const SizedBox(width: CajuiSpacing.sm),
        CajuiIconButton(
          icon: CajuiIconData.chevronRight,
          semanticLabel: 'Enviar pergunta',
          variant: CajuiButtonVariant.primary,
          onPressed: enabled ? _nothing : null,
        ),
      ],
    );
  }
}
