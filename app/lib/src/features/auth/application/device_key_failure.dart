import 'package:api_contract/api_contract.dart';

/// A recusa do Keystore do aparelho, já traduzida para o catálogo.
///
/// Existe porque assinar é a única coisa no app que pode falhar **fora do
/// Dart**: a chave vive no hardware, e o que volta de lá é um erro do
/// sistema. Sem um tipo próprio, esse erro subia como exceção de plataforma
/// e ninguém o pegava — a conversa ficava girando para sempre, esperando uma
/// resposta que nunca vinha.
final class DeviceKeyFailure implements Exception {
  /// Cria a recusa com o código que a pessoa vai ler.
  const new(this.code);

  /// O código do catálogo: `E-AUTH-01` quando o Keystore recusou,
  /// `E-AUTH-03` quando a chave foi invalidada e o aparelho precisa se
  /// cadastrar de novo.
  final ErrorCode code;

  @override
  String toString() => 'DeviceKeyFailure(${code.code})';
}
