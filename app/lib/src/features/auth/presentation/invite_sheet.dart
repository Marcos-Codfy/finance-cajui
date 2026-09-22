import 'package:cajui/src/features/auth/application/device_invite.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// O convite para o outro aparelho: o código, grande, e o que fazer com ele.
///
/// Grande de propósito — ele vai ser lido de um celular e digitado noutro
/// aparelho, às vezes de longe. E com o prazo à vista, porque um código que
/// venceu sem aviso parece defeito do app.
class InviteSheet extends StatelessWidget {
  /// Cria a tela do convite [invite].
  const new({required this.invite, super.key});

  /// O código e quanto ele dura.
  final DeviceInvite invite;

  /// Mostra o convite.
  static Future<void> show(BuildContext context, DeviceInvite invite) {
    return Navigator.of(
      context,
    ).push<void>(CajuiPageRoute(builder: (_) => InviteSheet(invite: invite)));
  }

  String get _duration {
    final minutes = invite.seconds ~/ 60;
    return minutes <= 1 ? 'um minuto' : '$minutes minutos';
  }

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return CajuiScreen(
      title: 'Cadastrar outro aparelho',
      onBack: Navigator.of(context).pop,
      footer: CajuiButton(
        label: 'Pronto',
        expand: true,
        onPressed: Navigator.of(context).pop,
      ),
      children: [
        Text(
          'No outro aparelho, abra o Cajui e escolha cadastrar. Digite este '
          'código:',
          style: theme.typography.body.copyWith(color: theme.colors.text.muted),
        ),
        const SizedBox(height: CajuiSpacing.xl),
        _code(theme),
        const SizedBox(height: CajuiSpacing.md),
        Text(
          'Vale por $_duration e serve uma vez só. Depois disso, aquele '
          'aparelho se identifica sozinho, pela chave dele.',
          style: theme.typography.caption.copyWith(
            color: theme.colors.text.faint,
          ),
        ),
      ],
    );
  }

  Widget _code(CajuiThemeData theme) => CajuiCard(
    sunken: true,
    child: Center(
      child: Text(
        invite.code,
        style: theme.typography.displayMedium,
        textAlign: TextAlign.center,
      ),
    ),
  );
}
