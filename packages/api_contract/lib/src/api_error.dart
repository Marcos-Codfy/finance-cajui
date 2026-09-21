import 'package:api_contract/src/error_code.dart';
import 'package:meta/meta.dart';

/// O corpo de **toda** resposta de erro da API — este, e nenhum outro:
///
/// ```json
/// {"error": {"code": "E-VOUCHER-01", "class": "regra",
///            "detail": {"balanceCents": 2260, "requestedCents": 3840},
///            "ref": "7f3a9c", "retryAfterSeconds": null}}
/// ```
///
/// A API manda o código e os **valores**; quem escreve a frase é o app, a
/// partir do catálogo. Assim nenhum texto técnico vaza para a tela, e trocar
/// uma redação não pede deploy do servidor.
@immutable
final class ApiError {
  /// Cria o erro.
  const new({
    required this.code,
    required this.ref,
    this.detail = const {},
    this.retryAfterSeconds,
  });

  /// Lê o corpo de erro de uma resposta. Código desconhecido — de um
  /// servidor mais novo que o app, por exemplo — vira `E-SRV-01`, mantendo o
  /// `ref`: o app nunca mostra um corpo cru.
  factory fromJson(Map<String, Object?> json) {
    final error = json['error'];
    if (error is! Map<String, Object?>) {
      return const ApiError(code: ErrorCode.srv01, ref: '');
    }
    final detail = error['detail'];
    return ApiError(
      code: ErrorCode.tryParse('${error['code']}') ?? ErrorCode.srv01,
      ref: '${error['ref'] ?? ''}',
      detail: detail is Map<String, Object?> ? detail : const {},
      retryAfterSeconds: error['retryAfterSeconds'] as int?,
    );
  }

  /// O código do catálogo.
  final ErrorCode code;

  /// O identificador da ocorrência no registro do servidor.
  final String ref;

  /// Só os valores que o texto do erro usa, já validados. Nunca texto livre,
  /// nunca pilha de execução.
  final Map<String, Object?> detail;

  /// Em quantos segundos dá para tentar de novo, nas classes `limite` e `ia`.
  final int? retryAfterSeconds;

  /// O corpo como vai na resposta.
  Map<String, Object?> toJson() => {
    'error': {
      'code': code.code,
      'class': code.errorClass.label,
      'detail': detail,
      'ref': ref,
      'retryAfterSeconds': retryAfterSeconds,
    },
  };
}
