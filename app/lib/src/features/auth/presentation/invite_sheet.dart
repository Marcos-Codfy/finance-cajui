import 'package:cajui/src/features/auth/application/device_invite.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// O convite: o código, grande, e o que fazer com ele.
///
/// Grande de propósito — ele vai ser lido de um celular e digitado noutro
/// aparelho, às vezes de longe. E com o prazo à vista, porque um código que
/// venceu sem aviso parece defeito do app.
///
/// São dois convites com a mesma cara: o de **outro celular**, que cadastra
/// um aparelho, e o do **computador**, que só abre a consulta. Mostrar o
/// texto de um no lugar do outro mandava a pessoa "abrir o Cajui no outro
/// aparelho" quando o que ela queria era o navegador.
class InviteSheet extends StatelessWidget {
  /// Cria a tela do convite [invite].
  const new({required this.invite, this.forWeb = false, super.key});

  /// O código e quanto ele dura.
  final DeviceInvite invite;

  /// Se o código abre a consulta no navegador, e não outro celular.
  final bool forWeb;

  /// Mostra o convite.
  static Future<void> show(
    BuildContext context,
    DeviceInvite invite, {
    bool forWeb = false,
  }) {
    return Navigator.of(context).push<void>(
      CajuiPageRoute(
        builder: (_) => InviteSheet(invite: invite, forWeb: forWeb),
      ),
    );
  }

  String get _duration {
    final minutes = invite.seconds ~/ 60;
    return minutes <= 1 ? 'um minuto' : '$minutes minutos';
  }

  String get _title =>
      forWeb ? 'Abrir no computador' : 'Cadastrar outro aparelho';

  String get _instruction => forWeb
      ? 'No computador, abra cajui-teal.vercel.app, toque em Assistente e '
            'escolha entrar com o código:'
      : 'No outro aparelho, abra o Cajui e escolha cadastrar. Digite este '
            'código:';

  String get _afterwards => forWeb
      ? 'Vale por $_duration e serve uma vez só. A consulta dura enquanto '
            'a aba do navegador ficar aberta.'
      : 'Vale por $_duration e serve uma vez só. Depois disso, aquele '
            'aparelho se identifica sozinho, pela chave dele.';

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return CajuiScreen(
      title: _title,
      onBack: Navigator.of(context).pop,
      footer: CajuiButton(
        label: 'Pronto',
        expand: true,
        onPressed: Navigator.of(context).pop,
      ),
      children: [
        Text(
          _instruction,
          style: theme.typography.body.copyWith(color: theme.colors.text.muted),
        ),
        const SizedBox(height: CajuiSpacing.xl),
        _code(theme),
        const SizedBox(height: CajuiSpacing.md),
        Text(
          _afterwards,
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
