import 'dart:typed_data';

import 'package:cajui/src/features/receipts/application/read_outcome.dart';
import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// Uma página de extrato como o celular a leu: o texto do OCR e, nas
/// primeiras páginas de um PDF ou num print, a imagem (ADR-022).
@immutable
final class StatementPage {
  /// Cria a página.
  const new({required this.text, this.image});

  /// As páginas de uma leitura do aparelho, na ordem: cada uma com o seu
  /// texto e, quando houve, a sua imagem.
  static List<StatementPage> ofRead(ReadText read) => [
    for (final (index, text) in read.pageTexts.indexed)
      StatementPage(text: text, image: read.imageOf(index + 1)),
  ];

  /// Menos quantias que isto, lidas pelo OCR, é texto fraco.
  static const _fewAmounts = 2;

  /// O texto lido no aparelho, sem máscara. Não sai do celular assim.
  final String text;

  /// A imagem da página, quando o leitor a produziu.
  final Uint8List? image;

  /// A imagem que vale mandar à IA: só quando o OCR da página veio fraco
  /// — uma página de extrato com movimentações traz quantias, e menos de
  /// duas é sinal de que o texto não foi lido (ADR-030, item 1). Com o
  /// texto bom, a imagem só gastaria rede e tokens.
  Uint8List? get imageForAi =>
      ReceiptFieldReader.amountsIn(text).length < _fewAmounts ? image : null;
}
