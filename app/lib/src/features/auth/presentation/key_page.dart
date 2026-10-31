import 'dart:async';

import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_notice.dart';
import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/features/auth/presentation/key_state.dart';
import 'package:cajui/src/features/auth/presentation/key_view_model.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Entrar na web: o código de seis dígitos do autenticador (ADR-027) ou a
/// chave da casa (ADR-020).
///
/// É a única tela que a consulta mostra antes do app. O código o dono tem
/// sempre à mão, no Google Authenticator; a chave longa continua valendo.
/// Uma vez aqui, a entrada fica neste navegador até a pessoa sair — com o
/// código, por trinta dias.
class KeyPage extends ConsumerStatefulWidget {
  /// Cria a tela de entrada.
  const new({super.key});

  @override
  ConsumerState<KeyPage> createState() => _KeyPageState();
}

class _KeyPageState extends ConsumerState<KeyPage> {
  final _key = TextEditingController();

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  void _enter() => unawaited(ref.read(keyProvider.notifier).enter(_key.text));

  /// Código que não serviu limpa o campo para o próximo — ele muda a cada
  /// trinta segundos.
  void _clearWhenCodeRefused(KeyState? before, KeyState now) {
    if (now is KeyEditing && now.problem?.code == ErrorCode.auth04) {
      _key.clear();
    }
  }

  List<Widget> _notice(PresentedError problem) => [
    ErrorNotice(
      error: problem,
      onAction: (_) => ref.read(keyProvider.notifier).dismissProblem(),
    ),
    const SizedBox(height: CajuiSpacing.lg),
  ];

  Widget _intro(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return Text(
      'Esta é a consulta do Cajui. Digite o código de seis dígitos do '
      'Cajui no seu autenticador, ou a chave da casa. Fica neste '
      'navegador até você sair.',
      style: theme.typography.body.copyWith(color: theme.colors.text.muted),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(keyProvider, _clearWhenCodeRefused);
    final form = ref.watch(keyProvider);
    final problem = form is KeyEditing ? form.problem : null;
    return CajuiScreen(
      title: 'Entrar',
      footer: CajuiButton(
        label: 'Entrar',
        expand: true,
        loading: form is KeyEntering,
        onPressed: KeyViewModel.isReady(_key.text) ? _enter : null,
      ),
      children: [
        _intro(context),
        const SizedBox(height: CajuiSpacing.xl),
        if (problem != null) ..._notice(problem),
        CajuiTextField(
          label: 'Código ou chave da casa',
          controller: _key,
          hint: '123456',
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => KeyViewModel.isReady(_key.text) ? _enter() : null,
        ),
      ],
    );
  }
}
