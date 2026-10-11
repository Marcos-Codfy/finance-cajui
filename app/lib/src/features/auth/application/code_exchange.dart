import 'package:api_contract/api_contract.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O que a troca devolve: o `token` da sessão, ou o `error` do catálogo que
/// explica por que não — com `retryAfterSeconds` quando o servidor pediu
/// pausa.
typedef CodeOutcome = ({
  String? token,
  ErrorCode? error,
  int? retryAfterSeconds,
});

/// A troca do código de seis dígitos do autenticador por uma sessão de
/// consulta (ADR-027). É o jeito curto de entrar na web: a chave da casa é
/// longa, e o código o dono tem sempre à mão no celular.
abstract interface class CodeExchange {
  /// A sessão aberta por [code]. O código que não serviu — errado, já usado
  /// ou com a entrada em espera — volta como `E-AUTH-04`; sem rede, com o
  /// limite de taxa ou com o servidor fora, o erro é o de cada caso, para a
  /// pessoa não achar que o autenticador está errado.
  Future<CodeOutcome> tokenFor(String code);
}

/// Quem troca o código. A raiz do app decide.
final codeExchangeProvider = Provider<CodeExchange>(
  (ref) => throw StateError('codeExchangeProvider sem override na raiz.'),
);
