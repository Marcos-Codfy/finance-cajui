import 'package:cajui/src/core/navigation/coordinator_access.dart';
import 'package:cajui/src/features/auth/application/household_key_store.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A chave da casa, para quem precisa dela em outro lugar: entrar na
/// consulta pela web de um computador que ainda não a tem (ADR-020).
///
/// Vem escondida, e aparece com um toque; copiar não exige mostrar. É a
/// única tela do app que exibe um segredo, e por isso ela é curta.
class HouseholdKeyPage extends ConsumerStatefulWidget {
  /// Cria a tela.
  const new({super.key});

  @override
  ConsumerState<HouseholdKeyPage> createState() => _HouseholdKeyPageState();
}

class _HouseholdKeyPageState extends ConsumerState<HouseholdKeyPage> {
  bool _shown = false;

  Future<void> _copy(String key) async {
    final feedback = CajuiFeedbackScope.of(context);
    await Clipboard.setData(ClipboardData(text: key));
    feedback.saved();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final key = ref.watch(householdKeyProvider).read();
    return CajuiScreen(
      title: 'Chave da casa',
      onBack: context.back,
      children: [
        _explanation(theme, key),
        if (key != null) ..._key(theme, key),
      ],
    );
  }

  Widget _explanation(CajuiThemeData theme, String? key) => Text(
    key == null
        ? 'Este app foi montado sem a chave da casa: ele funciona '
              'sozinho, sem servidor. O APK de uso vem com ela.'
        : 'É com ela que este celular, o outro e a consulta na web '
              'falam com o seu servidor. Para entrar na web de um '
              'computador novo, copie e cole lá.',
    style: theme.typography.body.copyWith(color: theme.colors.text.muted),
  );

  List<Widget> _key(CajuiThemeData theme, String key) => [
    const SizedBox(height: CajuiSpacing.xl),
    Text(
      _shown ? key : '•' * 24,
      style: theme.typography.body,
      semanticsLabel: _shown ? 'A chave da casa' : 'Chave escondida',
    ),
    const SizedBox(height: CajuiSpacing.lg),
    CajuiButton(label: 'Copiar', expand: true, onPressed: () => _copy(key)),
    const SizedBox(height: CajuiSpacing.sm),
    CajuiButton(
      label: _shown ? 'Esconder' : 'Mostrar',
      variant: CajuiButtonVariant.ghost,
      expand: true,
      onPressed: () => setState(() => _shown = !_shown),
    ),
  ];
}
