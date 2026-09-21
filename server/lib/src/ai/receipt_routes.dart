import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:server/src/ai/classification_prompt.dart';
import 'package:server/src/http/error_response.dart';
import 'package:server/src/http/json_body.dart';
import 'package:server/src/ledger/ledger_state.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// A rota de classificação de comprovante: recebe **só o texto** — a imagem
/// nunca sai do aparelho — e devolve uma proposta.
///
/// A resposta é sempre uma proposta válida. Quando a IA não participou, os
/// códigos do catálogo que explicam o porquê vêm em `warnings`, e o app
/// mostra o estado correspondente ("IA fora do ar", "teto de tokens").
final class ReceiptRoutes {
  /// Cria a rota sobre o classificador [classifier].
  new({required this.classifier, required this.state, required this.clock});

  /// Quem classifica: a IA por cima das regras, ou só as regras.
  final ReceiptClassifier classifier;

  /// O estado, de onde vem a lista fechada de categorias.
  final LedgerState state;

  /// O relógio, para recusar data futura.
  final Clock clock;

  /// O roteador, montado em `/v1/receipts`.
  Router get router => Router()..post('/classify', _classify);

  Future<Response> _classify(Request request) async {
    final json = await JsonBody.read(request);
    final body = JsonReader(json, allowed: const {'text', 'examples'});
    final proposal = await classifier.classify(
      ClassificationRequest(
        text: ReceiptText.clean(body.string('text', maxLength: 60000)),
        categories: state.categories.values.toList(),
        today: clock.today(),
        learnedRules: _examples(json),
      ),
    );
    return Responses.json(_json(proposal));
  }

  /// O que o aparelho aprendeu com as correções (RN-769): estabelecimento →
  /// categoria. É opcional e limitado; exemplo de categoria que o servidor
  /// não conhece é ignorado, e qualquer outra coisa fora do formato é pedido
  /// malformado.
  Map<String, String> _examples(Object? json) {
    final raw = json is Map<String, Object?> ? json['examples'] : null;
    if (raw == null) return const {};
    if (raw is! List<Object?> ||
        raw.length > ClassificationPrompt.maxExamples) {
      throw const FormatException('campo "examples" fora do formato');
    }
    final examples = <String, String>{};
    for (final item in raw) {
      final reader = JsonReader(
        item,
        allowed: const {'merchant', 'categoryId'},
      );
      final categoryId = reader.string('categoryId', maxLength: 64);
      final merchant = reader.string('merchant', maxLength: 80);
      if (state.categories.containsKey(categoryId)) {
        examples[merchant] = categoryId;
      }
    }
    return examples;
  }

  Map<String, Object?> _json(EntryProposal proposal) => {
    'documentKind': _field(proposal.documentKind, (kind) => kind.name),
    'amountCents': _field(proposal.amount, (money) => money.cents),
    'occurredOn': _field(proposal.occurredOn, (date) => '$date'),
    'categoryId': _field(proposal.category, (id) => id),
    'paymentKind': _field(proposal.paymentKind, (kind) => kind.name),
    'merchant': proposal.merchant,
    'description': proposal.description,
    'installments': proposal.installments,
    'warnings': proposal.warnings,
  };

  Map<String, Object?> _field<T>(
    ProposedField<T> field,
    Object Function(T value) encode,
  ) {
    final value = field.value;
    return {
      'value': value == null ? null : encode(value),
      'candidates': field.candidates.map(encode).toList(),
      'confidence': field.confidence.name,
      'source': field.source.name,
    };
  }
}
