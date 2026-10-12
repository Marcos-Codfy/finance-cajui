import 'dart:convert';
import 'dart:typed_data';

import 'package:api_contract/src/entry_codec.dart';
import 'package:api_contract/src/json_reader.dart';
import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// O pedido de leitura de uma página de extrato, em
/// `POST /v1/statements/read-part` (ADR-030).
///
/// As linhas vão numa lista, e o número de cada uma é a posição, a partir
/// de 1: é o número que a resposta cita, e por ele o celular volta ao texto
/// sem máscara, que nunca sai dele (RN-1106). Uma lista, e não um texto com
/// números escritos, para que nenhuma linha possa fingir o número de outra.
@immutable
final class StatementPageRequest {
  /// Cria o pedido.
  const new({
    required this.lines,
    required this.page,
    required this.pageCount,
    this.image,
    this.period,
    this.examples = const {},
  });

  /// O pedido em [json]. Lança [FormatException] no que não for exatamente
  /// o esperado — e a API responde `E-REQ-01`.
  factory fromJson(Object? json) {
    final body = JsonReader(json, allowed: _fields);
    final lines = _lines(body.optionalList('lines', maxItems: maxLines));
    final image = _image(
      body.optionalString('image', maxLength: maxImageBytes * 4 ~/ 3 + 4),
    );
    if (lines.isEmpty && image == null) {
      throw const FormatException('nem linha nem imagem');
    }
    final (page, count) = _pages(body);
    final period = body.optionalString('period', maxLength: 7);
    return StatementPageRequest(
      lines: lines,
      page: page,
      pageCount: count,
      image: image,
      period: period == null ? null : EntryCodec.parseMonth(period),
      examples: _examples(body.optionalList('examples', maxItems: 200)),
    );
  }

  static const _fields = {
    'lines',
    'page',
    'pageCount',
    'image',
    'period',
    'examples',
  };

  /// Quantas linhas uma página leva. Página de extrato tem algumas dezenas;
  /// o resto é ruído do OCR ou abuso.
  static const maxLines = 400;

  /// O maior tamanho de uma linha.
  static const maxLineLength = 300;

  /// O maior número de página: dez arquivos de vinte páginas (RN-1101).
  static const maxPages = 200;

  /// Quantos exemplos vão no pedido; valem os últimos, os mais recentes.
  static const maxExamples = 20;

  /// O maior nome de estabelecimento num exemplo.
  static const maxMerchantLength = 80;

  /// O maior tamanho da imagem, já decodificada.
  static const int maxImageBytes = 2 * 1024 * 1024;

  /// As linhas da página, já mascaradas, sem quebra de linha dentro.
  final List<String> lines;

  /// A página, a partir de 1.
  final int page;

  /// Quantas páginas a leitura tem.
  final int pageCount;

  /// A imagem da página, só quando o OCR dela veio fraco.
  final Uint8List? image;

  /// O mês do extrato, quando uma página anterior já o disse.
  final BudgetMonth? period;

  /// O que a pessoa já respondeu: chave do estabelecimento → categoria.
  /// Nunca as respostas sobre pessoas (RN-1107).
  final Map<String, String> examples;

  /// O pedido como vai pela rede.
  Map<String, Object?> toJson() => {
    'lines': lines,
    'page': page,
    'pageCount': pageCount,
    'image': ?_encoded(image),
    'period': ?period?.toString(),
    'examples': [
      for (final MapEntry(:key, :value) in _lastExamples(examples))
        {'merchant': key, 'categoryId': value},
    ],
  };

  static String? _encoded(Uint8List? image) =>
      image == null ? null : base64Encode(image);

  static Iterable<MapEntry<String, String>> _lastExamples(
    Map<String, String> examples,
  ) {
    final usable = examples.entries
        .where((entry) => entry.key.length <= maxMerchantLength)
        .toList();
    final extra = usable.length - maxExamples;
    return extra > 0 ? usable.sublist(extra) : usable;
  }

  static (int, int) _pages(JsonReader body) {
    final (page, count) = (body.integer('page'), body.integer('pageCount'));
    if (page < 1 || page > count || count > maxPages) {
      throw const FormatException('página fora do extrato');
    }
    return (page, count);
  }

  /// Linha com quebra dentro seria duas linhas com um número só.
  static List<String> _lines(List<Object?> raw) => [
    for (final line in raw)
      if (line is String &&
          line.length <= maxLineLength &&
          !line.contains('\n') &&
          !line.contains('\r'))
        line
      else
        throw const FormatException('linha'),
  ];

  static Uint8List? _image(String? encoded) {
    if (encoded == null) return null;
    final bytes = base64Decode(encoded);
    if (bytes.length > maxImageBytes) {
      throw const FormatException('imagem grande demais');
    }
    return bytes;
  }

  /// Exemplo a mais não recusa o pedido: valem os últimos.
  static Map<String, String> _examples(List<Object?> raw) {
    final extra = raw.length - maxExamples;
    final examples = <String, String>{};
    for (final item in extra > 0 ? raw.sublist(extra) : raw) {
      final reader = JsonReader(
        item,
        allowed: const {'merchant', 'categoryId'},
      );
      final merchant = reader.string('merchant', maxLength: maxMerchantLength);
      examples[merchant] = reader.string('categoryId', maxLength: 64);
    }
    return examples;
  }
}
