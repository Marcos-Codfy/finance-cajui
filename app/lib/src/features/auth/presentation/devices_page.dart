import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_notice.dart';
import 'package:cajui/src/features/assistant/presentation/assistant_reply_view.dart';
import 'package:cajui/src/features/auth/application/device_directory.dart';
import 'package:cajui/src/features/auth/application/device_invite.dart';
import 'package:cajui/src/features/auth/application/known_device.dart';
import 'package:cajui/src/features/auth/presentation/invite_sheet.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Quem tem acesso aos seus dados, e a porta para convidar mais um.
///
/// Está aqui porque "quem entra na minha casa" é pergunta que a pessoa deve
/// conseguir responder — e desfazer — sem pedir a ninguém. Revogar vale na
/// hora: a sessão do aparelho tirado morre junto.
class DevicesPage extends ConsumerStatefulWidget {
  /// Cria a tela de aparelhos.
  const new({super.key});

  /// Abre a tela.
  static Future<void> open(BuildContext context) {
    return Navigator.of(context)
        .push<void>(CajuiPageRoute(builder: (_) => const DevicesPage()));
  }

  @override
  ConsumerState<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends ConsumerState<DevicesPage> {
  late Future<(List<KnownDevice>, Object?)> _devices = _load();

  Future<(List<KnownDevice>, Object?)> _load() =>
      ref.read(deviceDirectoryProvider).devices();

  void _reload() => setState(() => _devices = _load());

  ErrorCode? _problem;

  /// O código que abre a consulta no navegador. É outro código, com outro
  /// prazo: ele não cadastra aparelho nenhum, só abre uma leitura.
  Future<void> _openOnComputer() =>
      _issue(ref.read(deviceDirectoryProvider).webInvite, forWeb: true);

  Future<void> _invite() => _issue(ref.read(deviceDirectoryProvider).invite);

  Future<void> _issue(
    Future<(DeviceInvite?, ErrorCode?)> Function() emitir, {
    bool forWeb = false,
  }) async {
    setState(() => _problem = null);
    final (invite, error) = await emitir();
    if (!mounted) return;
    // Sem isto, o botão principal não fazia nada quando o servidor não
    // respondia: nem aviso, nem carregando. A pessoa tocava de novo, e de
    // novo.
    if (invite == null) {
      setState(() => _problem = error ?? ErrorCode.srv01);
      return;
    }
    await InviteSheet.show(context, invite, forWeb: forWeb);
    _reload();
  }

  /// Revogar é ação de segurança: falhar calado deixaria a pessoa achando
  /// que tirou um aparelho que continua entrando.
  Future<void> _revoke(KnownDevice device) async {
    final error = await ref.read(deviceDirectoryProvider).revoke(device.id);
    if (!mounted) return;
    setState(() => _problem = error);
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return CajuiScreen(
      title: 'Aparelhos com acesso',
      onBack: Navigator.of(context).pop,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CajuiButton(
            label: 'Cadastrar outro aparelho',
            icon: CajuiIconData.plus,
            expand: true,
            onPressed: _invite,
          ),
          const SizedBox(height: CajuiSpacing.sm),
          CajuiButton(
            label: 'Abrir no computador',
            variant: CajuiButtonVariant.secondary,
            expand: true,
            onPressed: _openOnComputer,
          ),
        ],
      ),
      children: [_explanation(context), ..._notice(), ..._list()],
    );
  }

  List<Widget> _notice() {
    final code = _problem;
    if (code == null) return const [];
    return [
      const SizedBox(height: CajuiSpacing.lg),
      ErrorNotice(
        error: (code: code, text: AssistantReplyView.textOf(code)),
        onAction: (_) => setState(() => _problem = null),
      ),
    ];
  }

  Widget _explanation(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Text(
      'Cada aparelho entra com uma chave própria, que nasce dentro dele e '
      'nunca sai. Tirar um daqui vale na hora: a conversa dele com o '
      'servidor acaba no mesmo instante.',
      style: theme.typography.body.copyWith(color: theme.colors.text.muted),
    );
  }

  List<Widget> _list() => [
    FutureBuilder<(List<KnownDevice>, Object?)>(
      future: _devices,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) return const CajuiSkeleton(height: 56);
        final (devices, failure) = data;
        if (failure != null || devices.isEmpty) return _empty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final device in devices) _row(device)],
        );
      },
    ),
  ];

  static const _empty = CajuiEmptyState(
    title: 'Nenhum aparelho listado',
    message:
        'Ou este aparelho ainda não está cadastrado, ou o servidor não '
        'respondeu agora.',
  );

  Widget _row(KnownDevice device) => CajuiListRow(
    title: device.name,
    subtitle: device.isWeb ? 'Navegador · só leitura' : 'App · lê e lança',
    trailing: CajuiButton(
      label: 'Tirar',
      variant: CajuiButtonVariant.ghost,
      size: CajuiButtonSize.compact,
      onPressed: () => _revoke(device),
    ),
  );
}
