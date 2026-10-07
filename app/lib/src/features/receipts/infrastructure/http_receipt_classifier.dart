import 'dart:convert';

import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';
import 'package:cajui/src/features/receipts/application/reading_strategy.dart';
import 'package:domain/domain.dart';

/// A classificação do comprovante com a IA do servidor, junto das regras
/// locais (ADR-010, ADR-022).
///
/// Três coisas governam este adaptador.
///
/// **O celular lê primeiro.** As regras rodam aqui, sobre o texto da foto.
/// Quando elas bastam — o cupom de mercado com "TOTAL", data e nome do lugar
/// —, nada sai do aparelho e o comprovante abre na hora.
///
/// **Quando não bastam, a foto vai junto.** A IA recebe a imagem e o texto
/// lido dela, e o servidor junta as duas leituras campo a campo.
///
/// **As regras são a rede.** Sem a chave da casa, sem rede, servidor fora do
/// ar, IA sem crédito: vale a proposta local. Nada quebra por falta de IA
/// (RN-752).
final class HttpReceiptClassifier implements ReceiptClassifier {
  /// Cria o classificador sobre [_api], com [_rules] por baixo.
  const new(this._api, this._rules);

  final CajuiApi _api;
  final ReceiptClassifier _rules;

  @override
  Future<EntryProposal> classify(ClassificationRequest request) async {
    final local = await _rules.classify(request);
    if (!_api.hasKey || ReadingStrategy.rulesSuffice(local)) return local;
    final remote = await _fromServer(request);
    return remote == null ? local : ReadingStrategy.blend(remote, local);
  }

  Future<EntryProposal?> _fromServer(ClassificationRequest request) async {
    try {
      final outcome = await _api.authenticated(
        (token) => _api.post('/v1/receipts/classify', {
          if (request.text.isNotEmpty) 'text': request.text,
          'examples': _examples(request),
          if (request.hasImages)
            'images': [for (final image in request.images) base64Encode(image)],
        }, token: token),
      );
      final body = outcome.body;
      if (body == null) return null;
      return ProposalCodec.decode(body, knowsCategory: _knows(request));
    } on Object {
      // Resposta fora do formato é o mesmo que resposta nenhuma: cai nas
      // regras, que é o caminho que sempre funciona.
      return null;
    }
  }

  /// A lista fechada deste aparelho (RN-742): categoria que ele não tem não
  /// entra na proposta, venha de onde vier.
  bool Function(String) _knows(ClassificationRequest request) =>
      (id) => request.categories.any((category) => category.id == id);

  /// O que o aparelho aprendeu com as correções, para a IA não repetir um
  /// erro já corrigido (RN-769).
  List<Map<String, Object?>> _examples(ClassificationRequest request) => [
    for (final MapEntry(key: merchant, value: categoryId)
        in request.learnedRules.entries)
      {'merchant': merchant, 'categoryId': categoryId},
  ];
}
