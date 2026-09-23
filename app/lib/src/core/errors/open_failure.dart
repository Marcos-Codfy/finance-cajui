import 'package:api_contract/api_contract.dart';
import 'package:persistence/persistence.dart';

/// Por que o livro não abriu, no código do catálogo que a tela mostra.
///
/// A tela dizia `E-APP-01` para tudo, e as três causas pedem saídas
/// diferentes: cadeia quebrada pede conferir o registro, falta de espaço
/// pede liberar espaço, e o resto pede reabrir. O adaptador já sabia
/// distingui-las e a informação morria no caminho (BL-033).
abstract final class OpenFailure {
  /// O código para a falha [error].
  static ErrorCode codeOf(Object? error) => switch (error) {
    LogIntegrityException() || RecordTamperedException() => ErrorCode.data01,
    StorageFullException() => ErrorCode.storage01,
    _ => ErrorCode.app01,
  };
}
