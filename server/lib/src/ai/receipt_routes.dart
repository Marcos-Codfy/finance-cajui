import 'dart:convert';
import 'dart:typed_data';

import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:server/src/ai/classification_prompt.dart';
import 'package:server/src/ai/receipt_image.dart';
import 'package:server/src/http/error_response.dart';
import 'package:server/src/http/json_body.dart';
import 'package:server/src/ledger/ledger_state.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// A rota de classificação de comprovante: recebe o texto que o celular
/// leu e, quando houver, as imagens do documento (ADR-022), e devolve uma
/// proposta. Texto vazio com imagem é o comprovante que o celular não
/// conseguiu ler: a IA lê sozinha.
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

  /// O maior corpo aceito aqui: três imagens e o texto.
  static const int maxBodyBytes = 12 * 1024 * 1024;

  /// Quantas imagens um comprovante leva: a foto, ou as primeiras páginas.
  static const maxImages = 3;

  /// O maior tamanho de uma imagem, já decodificada.
  static const int maxImageBytes = 4 * 1024 * 1024;

  Future<Response> _classify(Request request) async {
    final json = await JsonBody.read(request, limit: maxBodyBytes);
    final body = JsonReader(
      json,
      allowed: const {'text', 'examples', 'images'},
    );
    final images = _images(json);
    final text = body.optionalString('text', maxLength: 60000) ?? '';
    if (text.isEmpty && images.isEmpty) {
      throw const FormatException('nem texto nem imagem');
    }
    final proposal = await classifier.classify(
      ClassificationRequest(
        text: ReceiptText.clean(text),
        categories: state.categories.values.toList(),
        today: clock.today(),
        learnedRules: _examples(json),
        images: images,
      ),
    );
    return Responses.json(ProposalCodec.encode(proposal));
  }

  /// As imagens, em base64. Cada uma é conferida pelos primeiros bytes: o
  /// que não for JPEG, PNG ou WebP é pedido malformado, e não sai daqui.
  List<Uint8List> _images(Object? json) {
    final raw = json is Map<String, Object?> ? json['images'] : null;
    if (raw == null) return const [];
    if (raw is! List<Object?> || raw.length > maxImages) {
      throw const FormatException('campo "images" fora do formato');
    }
    return [
      for (final item in raw)
        if (item is String)
          _image(item)
        else
          throw const FormatException('imagem'),
    ];
  }

  static Uint8List _image(String encoded) {
    final bytes = base64Decode(encoded);
    if (bytes.length > maxImageBytes || ReceiptImage.mimeOf(bytes) == null) {
      throw const FormatException('imagem fora do formato');
    }
    return bytes;
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
}
