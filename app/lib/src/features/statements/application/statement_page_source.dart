import 'package:api_contract/api_contract.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// O que deu a leitura de uma página: a resposta, ou o código do catálogo
/// que diz por que não houve.
typedef StatementPageOutcome = ({
  StatementPageReply? reply,
  ErrorCode? failure,
});

/// Por onde o app pede a leitura de uma página de extrato (ADR-030).
///
/// A IA só lê; a página vai já mascarada, e a resposta traz só o que
/// passou nas conferências do servidor. Quem faz o laço pelas páginas, e
/// tenta de novo a que falha, é o caso de uso, aqui no celular.
abstract interface class StatementPageSource {
  /// Lê a página [request]. Categoria que [knowsCategory] não conhece fica
  /// de fora da resposta (RN-742).
  Future<StatementPageOutcome> read(
    StatementPageRequest request, {
    required bool Function(String id) knowsCategory,
  });
}

/// O caminho até a leitura de páginas. A raiz do app decide qual.
final statementPageSourceProvider = Provider<StatementPageSource>(
  (ref) =>
      throw StateError('statementPageSourceProvider sem override na raiz.'),
);
