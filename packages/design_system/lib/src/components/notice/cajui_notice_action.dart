import 'package:flutter/widgets.dart';

/// Uma saída oferecida por um aviso: "Tirar outra foto", "Digitar os dados".
///
/// O catálogo de erros exige que toda mensagem termine no que o usuário pode
/// fazer agora. Esta classe é esse "o que fazer", em forma de botão.
@immutable
class CajuiNoticeAction {
  /// Cria a ação com o rótulo [label], no infinitivo.
  const new({required this.label, required this.onPressed});

  /// O rótulo do botão.
  final String label;

  /// O que acontece ao tocar.
  final VoidCallback onPressed;
}
