import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A troca do código de seis dígitos do autenticador por uma sessão de
/// consulta (ADR-027). É o jeito curto de entrar na web: a chave da casa é
/// longa, e o código o dono tem sempre à mão no celular.
abstract interface class CodeExchange {
  /// O token da sessão aberta por [code], ou `null` quando o código não
  /// serviu — errado, já usado ou com a entrada em espera.
  Future<String?> tokenFor(String code);
}

/// Quem troca o código. A raiz do app decide.
final codeExchangeProvider = Provider<CodeExchange>(
  (ref) => throw StateError('codeExchangeProvider sem override na raiz.'),
);
