import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/error_texts.g.dart';
import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/features/auth/application/code_exchange.dart';
import 'package:cajui/src/features/auth/application/household_key_presence.dart';
import 'package:cajui/src/features/auth/application/household_key_store.dart';
import 'package:cajui/src/features/auth/presentation/key_state.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O ViewModel da entrada da consulta (ADR-002, ADR-020, ADR-027).
///
/// Decide se o que foi digitado é o código de seis dígitos do autenticador ou
/// a chave da casa, confere com o servidor quando é código, guarda a chave e
/// manda reler o livro. A tela só desenha o campo e escuta o estado.
class KeyViewModel extends Notifier<KeyState> {
  /// Chave mais curta que isto não é a chave: é um engano de digitação, e
  /// mandar ao servidor só renderia uma recusa.
  static const _minLength = 16;

  static final _sixDigits = RegExp(r'^\d{6}$');

  /// O código sem espaços: o Google Authenticator o mostra em dois grupos de
  /// três, e é assim que muita gente digita.
  static String digitsOf(String typed) =>
      typed.trim().replaceAll(RegExp(r'\s'), '');

  /// Se [typed] é o código do autenticador.
  static bool isCode(String typed) => _sixDigits.hasMatch(digitsOf(typed));

  /// Se [typed] já dá para mandar: um código inteiro ou uma chave do tamanho
  /// da chave.
  static bool isReady(String typed) =>
      isCode(typed) || typed.trim().length >= _minLength;

  @override
  KeyState build() => const KeyEditing();

  /// Confere [typed] e, se serviu, guarda a chave e relê o livro.
  Future<void> enter(String typed) async {
    if (state is KeyEntering || !isReady(typed)) return;
    state = const KeyEntering();
    final outcome = isCode(typed)
        ? await ref.read(codeExchangeProvider).tokenFor(digitsOf(typed))
        : (token: typed.trim(), error: null, retryAfterSeconds: null);
    if (!ref.mounted) return;
    final secret = outcome.token;
    if (secret == null) {
      state = KeyEditing(problem: _problemOf(outcome));
      return;
    }
    await ref.read(householdKeyProvider).write(secret);
    if (!ref.mounted) return;
    // O livro da consulta é o que o servidor tem, e foi lido antes de haver
    // chave — vazio. Relido agora, com ela.
    ref
      ..invalidate(ledgerProvider)
      ..read(hasHouseholdKeyProvider.notifier).refresh();
    state = const KeyEntered();
  }

  /// Dispensa o aviso.
  void dismissProblem() => state = const KeyEditing();

  /// Não entrou: a frase do catálogo para o caso.
  static PresentedError _problemOf(CodeOutcome outcome) {
    final code = outcome.error ?? ErrorCode.auth04;
    return (
      code: code,
      text: ErrorTexts.of(code).fill({
        'recurso': 'Entrar na consulta',
        'segundos': '${outcome.retryAfterSeconds ?? 60}',
        'ação': 'conferir o código',
      }),
    );
  }
}

/// O ViewModel da entrada. Descartado ao fechar a tela.
final NotifierProvider<KeyViewModel, KeyState> keyProvider =
    NotifierProvider.autoDispose(KeyViewModel.new);
