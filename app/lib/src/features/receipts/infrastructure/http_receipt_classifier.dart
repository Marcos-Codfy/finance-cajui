import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';
import 'package:domain/domain.dart';

/// A classificação do comprovante com a IA do servidor, por cima das regras
/// locais (ADR-010).
///
/// O servidor tinha a rota `POST /v1/receipts/classify` desde a Fase 6 e
/// **ninguém a chamava**: a IA estava construída e desligada, e todo
/// comprovante era lido só pelas regras.
///
/// Duas coisas governam este adaptador.
///
/// **Só o texto sai daqui, nunca a imagem.** É a regra do dono e é o que a
/// rota aceita: o comprovante é lido no aparelho, e o que viaja é o que o
/// OCR extraiu.
///
/// **As regras são a rede, e não o contrário.** Sem sessão aberta, sem rede,
/// servidor fora do ar, IA sem crédito — em qualquer um desses casos vale a
/// proposta local, que é exata no que sabe. Nada quebra por falta de IA
/// (RN-752).
final class HttpReceiptClassifier implements ReceiptClassifier {
  /// Cria o classificador sobre [_api], com [_rules] por baixo.
  const new(this._api, this._rules);

  final CajuiApi _api;
  final ReceiptClassifier _rules;

  @override
  Future<EntryProposal> classify(ClassificationRequest request) async {
    final local = await _rules.classify(request);
    // Abrir sessão pede a digital, e pedir a digital no meio de uma
    // conferência de comprovante é pior do que classificar só com as regras.
    // Depois do primeiro envio do dia a sessão já está aberta, e aí a IA
    // entra sem custo nenhum para quem está usando.
    if (!_api.isOpen) return local;
    return await _fromServer(request) ?? local;
  }

  Future<EntryProposal?> _fromServer(ClassificationRequest request) async {
    try {
      final outcome = await _api.authenticated(
        (token) => _api.post('/v1/receipts/classify', {
          'text': request.text,
          'examples': _examples(request),
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
