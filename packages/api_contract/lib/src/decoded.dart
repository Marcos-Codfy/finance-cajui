import 'package:api_contract/src/error_code.dart';
import 'package:meta/meta.dart';

/// O resultado de ler o que veio de fora: ou foi entendido, ou foi recusado
/// com o código do catálogo.
///
/// Os decodificadores do contrato conferem campo a campo e lançam
/// [FormatException] no primeiro que não bate (RNF-SEC-09): é o jeito mais
/// curto de escrever uma leitura estrita. [Decoded.of] é a fronteira: a
/// exceção nasce e morre ali, e quem chama recebe um valor e um `switch`
/// exaustivo, em vez de depender de um `catch` que alguém precisa lembrar de
/// pôr.
@immutable
sealed class Decoded<T> {
  const new();

  /// Lê com [read]. Pedido malformado vira [Refused] com `E-REQ-01`.
  ///
  /// Só a [FormatException] é tratada aqui: qualquer outra exceção é defeito
  /// do programa, e não de quem mandou o pedido, e continua subindo.
  static Decoded<T> of<T>(T Function() read) {
    try {
      return Understood<T>(read());
    } on FormatException {
      return const Refused<Never>(ErrorCode.req01);
    }
  }
}

/// O pedido foi entendido, e este é o valor lido.
final class Understood<T> extends Decoded<T> {
  /// Cria o resultado de leitura bem-sucedida com [value].
  const new(this.value);

  /// O que foi lido.
  final T value;
}

/// O pedido foi recusado, e este é o código do catálogo que explica.
final class Refused<T> extends Decoded<T> {
  /// Cria a recusa com [code].
  const new(this.code);

  /// O código do catálogo: `E-REQ-01` para pedido malformado, `E-REQ-04`
  /// para corpo grande demais.
  final ErrorCode code;
}
