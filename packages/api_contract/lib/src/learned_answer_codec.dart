import 'package:api_contract/src/device_fact.dart';
import 'package:api_contract/src/json_reader.dart';
import 'package:domain/domain.dart';

/// A ida e a volta de uma resposta lembrada (RN-1116) com o registro — o do
/// aparelho e o do servidor, que a guarda para o outro celular (ADR-030).
///
/// Antes a memória de classificação morava só no aparelho que a aprendeu:
/// reinstalar perdia tudo, e o outro celular perguntava de novo. Agora ela
/// é um fato como os nomes da casa, e a mais nova vence.
abstract final class LearnedAnswerCodec {
  /// O que gravar para [answer].
  static Map<String, Object?> encode(LearnedAnswer answer) => {
    'key': answer.key,
    'categoryId': answer.categoryId,
    'treatment': answer.treatment?.name,
    'aboutPerson': answer.aboutPerson,
    'definedAt': answer.definedAt.toUtc().toIso8601String(),
  };

  /// A resposta gravada em [payload]. Recusa o que não fecha — chave vazia
  /// ou longa demais, tratamento que não existe, carimbo sem fuso —, porque
  /// o servidor guarda o que recebe e conferir é a única barreira (T-05).
  static LearnedAnswer decode(Map<String, Object?> payload) {
    final key = payload['key'];
    final definedAt = JsonReader.instantOf(payload['definedAt']);
    final aboutPerson = payload['aboutPerson'] ?? false;
    if (key is! String || !fits(key)) {
      throw const FormatException('chave da resposta');
    }
    if (definedAt == null || aboutPerson is! bool) {
      throw const FormatException('resposta lembrada');
    }
    return LearnedAnswer(
      key: key,
      definedAt: definedAt,
      categoryId: _category(payload['categoryId']),
      treatment: _treatment(payload['treatment']),
      aboutPerson: aboutPerson,
    );
  }

  /// Se [key] cabe num fato: texto não vazio, até o teto de um fato. Quem
  /// lembra confere antes, e a chave que não cabe não é lembrada — o
  /// servidor a recusaria, e a sincronização tropeçaria nela para sempre.
  static bool fits(Object? key) =>
      key is String &&
      key.trim().isNotEmpty &&
      key.length <= DeviceFact.maxText;

  static String? _category(Object? raw) {
    if (raw == null) return null;
    if (raw is! String || raw.isEmpty || raw.length > _maxCategoryId) {
      throw const FormatException('categoria da resposta');
    }
    return raw;
  }

  /// O identificador de categoria tem o mesmo teto do resto do contrato.
  static const _maxCategoryId = 64;

  static LineTreatment? _treatment(Object? raw) {
    if (raw == null) return null;
    for (final treatment in LineTreatment.values) {
      if (treatment.name == raw) return treatment;
    }
    throw const FormatException('tratamento da resposta');
  }
}
