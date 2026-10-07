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
/// Quando elas bastam — o cupom de mercado com "TOTAL", data, forma de
/// pagamento e nome do lugar —, nada sai do aparelho e o comprovante abre na
/// hora.
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

  /// Quantos exemplos o servidor aceita num pedido — a mesma conta do prompt
  /// lá. Vão os mais recentes.
  static const maxExamples = 20;

  /// O maior nome de estabelecimento que o servidor aceita num exemplo.
  static const maxMerchantLength = 80;

  /// Até quanto tempo uma falha de rede ainda é "o servidor cortou o envio",
  /// e não "a rede caiu": o servidor antigo fecha a conexão logo que o corpo
  /// passa do teto dele.
  static const _quickFailure = Duration(seconds: 10);

  @override
  Future<EntryProposal> classify(ClassificationRequest request) async {
    final local = await _rules.classify(request);
    if (!_worthAsking(request, local)) return local;
    final remote = await _fromServer(request);
    return remote == null ? local : ReadingStrategy.blend(remote, local);
  }

  /// Se vale perguntar ao servidor: há chave, a regra não bastou, e há o que
  /// mandar — sem texto e sem imagem o servidor só recusaria.
  bool _worthAsking(ClassificationRequest request, EntryProposal local) =>
      _api.hasKey &&
      !ReadingStrategy.rulesSuffice(local) &&
      (request.text.trim().isNotEmpty || request.hasImages);

  Future<EntryProposal?> _fromServer(ClassificationRequest request) async {
    final watch = Stopwatch()..start();
    var outcome = await _post(request, withImages: request.hasImages);
    if (_refusedThePhoto(request, outcome, watch.elapsed)) {
      outcome = await _post(request, withImages: false);
    }
    final body = outcome.body;
    if (body == null) return null;
    try {
      return ProposalCodec.decode(body, knowsCategory: _knows(request));
    } on Object {
      // Resposta fora do formato é o mesmo que resposta nenhuma: cai nas
      // regras, que é o caminho que sempre funciona.
      return null;
    }
  }

  Future<ApiOutcome> _post(
    ClassificationRequest request, {
    required bool withImages,
  }) => _api.authenticated(
    (token) => _api.post(
      '/v1/receipts/classify',
      {
        if (request.text.isNotEmpty) 'text': request.text,
        'examples': _examples(request),
        if (withImages)
          'images': [for (final image in request.images) base64Encode(image)],
      },
      token: token,
      waitFor: withImages ? CajuiApi.readingTimeout : CajuiApi.timeout,
    ),
  );

  /// O servidor que ainda não conhece foto recusa o pedido: malformado,
  /// grande demais, ou a conexão cortada no meio do envio. Com texto, o
  /// pedido de antes — sem as imagens — ele sabe responder, e a IA continua
  /// ajudando até o servidor ser atualizado.
  static bool _refusedThePhoto(
    ClassificationRequest request,
    ApiOutcome outcome,
    Duration took,
  ) {
    final code = outcome.failure?.code;
    if (code == null || !request.hasImages) return false;
    if (request.text.trim().isEmpty) return false;
    return code == ErrorCode.req01 ||
        code == ErrorCode.req04 ||
        (code == ErrorCode.net01 && took < _quickFailure);
  }

  /// A lista fechada deste aparelho (RN-742): categoria que ele não tem não
  /// entra na proposta, venha de onde vier.
  bool Function(String) _knows(ClassificationRequest request) =>
      (id) => request.categories.any((category) => category.id == id);

  /// O que o aparelho aprendeu com as correções, para a IA não repetir um
  /// erro já corrigido (RN-769). Exemplo a mais fazia o servidor recusar o
  /// pedido inteiro — e a foto deixava de chegar à IA sem aviso nenhum.
  List<Map<String, Object?>> _examples(ClassificationRequest request) {
    final usable = [
      for (final MapEntry(key: merchant, value: categoryId)
          in request.learnedRules.entries)
        if (merchant.length <= maxMerchantLength)
          {'merchant': merchant, 'categoryId': categoryId},
    ];
    final extra = usable.length - maxExamples;
    return extra > 0 ? usable.sublist(extra) : usable;
  }
}
