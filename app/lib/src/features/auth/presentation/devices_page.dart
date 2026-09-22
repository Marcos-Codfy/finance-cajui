import 'package:cajui/src/features/auth/application/device_directory.dart';
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

  Future<void> _invite() async {
    final (invite, _) = await ref.read(deviceDirectoryProvider).invite();
    if (!mounted || invite == null) return;
    await InviteSheet.show(context, invite);
    _reload();
  }

  Future<void> _revoke(KnownDevice device) async {
    await ref.read(deviceDirectoryProvider).revoke(device.id);
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return CajuiScreen(
      title: 'Aparelhos com acesso',
      onBack: Navigator.of(context).pop,
      footer: CajuiButton(
        label: 'Cadastrar outro aparelho',
        icon: CajuiIconData.plus,
        expand: true,
        onPressed: _invite,
      ),
      children: [_explanation(context), ..._list()],
    );
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
