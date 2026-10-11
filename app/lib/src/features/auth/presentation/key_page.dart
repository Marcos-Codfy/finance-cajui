import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_notice.dart';
import 'package:cajui/src/core/errors/error_texts.g.dart';
import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/features/auth/application/code_exchange.dart';
import 'package:cajui/src/features/auth/application/household_key_presence.dart';
import 'package:cajui/src/features/auth/application/household_key_store.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
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
  bool _saving = false;
  PresentedError? _problem;

  /// Chave mais curta que isto não é a chave: é um engano de digitação, e
  /// mandar ao servidor só renderia uma recusa.
  static const _minLength = 16;

  static final _sixDigits = RegExp(r'^\d{6}$');

  String get _typed => _key.text.trim();

  /// O código sem espaços: o Google Authenticator o mostra em dois grupos
  /// de três, e é assim que muita gente digita.
  String get _digits => _typed.replaceAll(RegExp(r'\s'), '');

  bool get _isCode => _sixDigits.hasMatch(_digits);

  bool get _ready => _isCode || _typed.length >= _minLength;

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _enter() async {
    setState(() {
      _saving = true;
      _problem = null;
    });
    final outcome = _isCode
        ? await ref.read(codeExchangeProvider).tokenFor(_digits)
        : (token: _typed, error: null, retryAfterSeconds: null);
    if (!mounted) return;
    final secret = outcome.token;
    if (secret == null) return _refused(outcome);
    await ref.read(householdKeyProvider).write(secret);
    if (!mounted) return;
    // O livro da consulta é o que o servidor tem, e foi lido antes de haver
    // chave — vazio. Relido agora, com ela.
    ref
      ..invalidate(ledgerProvider)
      ..read(hasHouseholdKeyProvider.notifier).refresh();
  }

  /// Não entrou: a frase do catálogo para o caso. Código que não serviu
  /// limpa o campo para o próximo — ele muda a cada trinta segundos.
  void _refused(CodeOutcome outcome) => setState(() {
    final code = outcome.error ?? ErrorCode.auth04;
    _saving = false;
    if (code == ErrorCode.auth04) _key.clear();
    _problem = (
      code: code,
      text: ErrorTexts.of(code).fill({
        'recurso': 'Entrar na consulta',
        'segundos': '${outcome.retryAfterSeconds ?? 60}',
        'ação': 'conferir o código',
      }),
    );
  });

  List<Widget> _notice(PresentedError problem) => [
    ErrorNotice(
      error: problem,
      onAction: (_) => setState(() => _problem = null),
    ),
    const SizedBox(height: CajuiSpacing.lg),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = CajuiTheme.of(context);
    final problem = _problem;
    return CajuiScreen(
      title: 'Entrar',
      footer: CajuiButton(
        label: 'Entrar',
        expand: true,
        loading: _saving,
        onPressed: _ready ? _enter : null,
      ),
      children: [
        Text(
          'Esta é a consulta do Cajui. Digite o código de seis dígitos do '
          'Cajui no seu autenticador, ou a chave da casa. Fica neste '
          'navegador até você sair.',
          style: theme.typography.body.copyWith(color: theme.colors.text.muted),
        ),
        const SizedBox(height: CajuiSpacing.xl),
        if (problem != null) ..._notice(problem),
        CajuiTextField(
          label: 'Código ou chave da casa',
          controller: _key,
          hint: '123456',
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _ready ? _enter() : null,
        ),
      ],
    );
  }
}
