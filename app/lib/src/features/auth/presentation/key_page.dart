import 'package:cajui/src/features/auth/application/household_key_presence.dart';
import 'package:cajui/src/features/auth/application/household_key_store.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Entrar na web: a chave da casa, uma vez (ADR-020).
///
/// É a única tela que a consulta mostra antes do app. A chave está no
/// computador do dono, em Documentos, e em Ajustes do celular; digitada
/// aqui, fica neste navegador até a pessoa sair.
class KeyPage extends ConsumerStatefulWidget {
  /// Cria a tela de entrada.
  const new({super.key});

  @override
  ConsumerState<KeyPage> createState() => _KeyPageState();
}

class _KeyPageState extends ConsumerState<KeyPage> {
  final _key = TextEditingController();
  bool _saving = false;

  /// Chave mais curta que isto não é a chave: é um engano de digitação, e
  /// mandar ao servidor só renderia uma recusa.
  static const _minLength = 16;

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _enter() async {
    setState(() => _saving = true);
    await ref.read(householdKeyProvider).write(_key.text);
    if (!mounted) return;
    // O livro da consulta é o que o servidor tem, e foi lido antes de haver
    // chave — vazio. Relido agora, com ela.
    ref
      ..invalidate(ledgerProvider)
      ..read(hasHouseholdKeyProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    return CajuiScreen(
      title: 'Entrar',
      footer: CajuiButton(
        label: 'Entrar',
        expand: true,
        loading: _saving,
        onPressed: _key.text.trim().length >= _minLength ? _enter : null,
      ),
      children: [
        Text(
          'Esta é a consulta do Cajui. Digite a chave da casa: ela está em '
          'Ajustes, no celular, e no arquivo guardado no seu computador. '
          'Fica neste navegador até você sair.',
          style: theme.typography.body.copyWith(color: theme.colors.text.muted),
        ),
        const SizedBox(height: CajuiSpacing.xl),
        CajuiTextField(
          label: 'Chave da casa',
          controller: _key,
          hint: 'cole a chave aqui',
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _enter(),
        ),
      ],
    );
  }
}
