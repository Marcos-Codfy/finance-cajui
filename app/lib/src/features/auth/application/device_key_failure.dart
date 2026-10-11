import 'package:api_contract/api_contract.dart';

/// A recusa do Keystore do aparelho, já traduzida para o catálogo.
///
/// Existe porque ler a chave é coisa que pode falhar **fora do Dart**: ela
/// vive no hardware, e o que volta de lá é um erro do sistema. Sem um tipo
/// próprio, esse erro subia como exceção de plataforma e ninguém o pegava —
/// a conversa ficava girando para sempre, esperando uma resposta que nunca
/// vinha. Quem lê a chave para dar nome ao aparelho pega esta falha e
/// segue com um nome genérico.
final class DeviceKeyFailure implements Exception {
  /// Cria a recusa com o código que a pessoa vai ler.
  const new(this.code);

  /// O código do catálogo: o que o lado nativo mandou, ou `E-AUTH-01`
  /// quando ele não mandou nenhum que o catálogo conheça.
  final ErrorCode code;

  @override
  String toString() => 'DeviceKeyFailure(${code.code})';
}
