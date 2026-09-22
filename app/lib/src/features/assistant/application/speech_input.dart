import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ditar a pergunta em vez de digitá-la (ADR-018).
///
/// É uma porta porque quem ouve **não é o Cajui**: é o reconhecedor do
/// aparelho. O app não grava áudio, não guarda áudio e não manda áudio para
/// lugar nenhum — o que atravessa esta interface já é texto.
abstract interface class SpeechInput {
  /// Se este aparelho tem como ouvir. Sem isso, o botão não aparece.
  Future<bool> isAvailable();

  /// Ouve uma frase e devolve o que entendeu, ou `null` se a pessoa desistiu
  /// ou nada foi dito.
  Future<String?> listen();
}

/// Quem ouve por aqui. A raiz do app decide.
final speechInputProvider = Provider<SpeechInput>(
  (ref) => throw StateError('speechInputProvider sem override na raiz.'),
);
