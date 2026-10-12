import 'package:domain/src/household/person_name.dart';
import 'package:domain/src/receipts/statement_line.dart';
import 'package:domain/src/statements/merchant_brand.dart';

/// As duas chaves de uma linha de extrato: a da memória das respostas
/// (RN-1116) e a do conteúdo, para a chave da linha gravada (RN-1117).
///
/// São separadas porque servem a coisas diferentes. A da memória precisa
/// reconhecer o mesmo lugar em extratos e comprovantes diferentes: sai da
/// marca, do nome da pessoa ou da descrição limpa. A do conteúdo precisa ser
/// a mesma toda vez que o mesmo arquivo é lido: sai do texto que o celular
/// leu, e não da descrição da IA, que pode mudar de uma leitura para outra.
abstract final class StatementLineKeys {
  /// O prefixo da chave de uma pessoa.
  static const personPrefix = 'pessoa:';

  /// O nome que a leitura dá à linha sem nome que preste.
  static const unnamed = 'Movimentação';

  /// As chaves de [raw]. A da memória fica vazia quando a linha não tem
  /// nome que sirva — "Movimentação", ou um nome mascarado sem o original:
  /// uma resposta sobre ela não pode valer para todas as outras sem nome.
  static ({String memory, String content}) of(
    StatementLine raw,
    String? original,
    String? person,
    MerchantBrand? brand,
  ) {
    final fromText = original == null ? '' : _textKey(original);
    final memory = switch ((person, brand)) {
      (final String who, _) => '$personPrefix${_person(who)}',
      (_, final MerchantBrand mark) => MerchantBrand.keyOf(mark.name),
      _ when _generic(raw.description) => fromText,
      _ => MerchantBrand.keyOf(raw.description),
    };
    return (memory: memory, content: fromText.isEmpty ? memory : fromText);
  }

  static String _person(String who) => PersonName.of(who).words.join(' ');

  static bool _generic(String description) =>
      description.trim() == unnamed || description.contains('[');

  /// A linha sem data, valor, sinal e números soltos: o que sobra é o nome
  /// do lugar como o banco escreveu, igual em toda leitura do mesmo
  /// arquivo.
  static String _textKey(String original) {
    final words = original
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty && !_isNumberish(word));
    return MerchantBrand.keyOf(words.join(' '));
  }

  static bool _isNumberish(String word) =>
      RegExp(r'\d').hasMatch(word) || _currency.contains(word.toUpperCase());

  static const _currency = {r'R$', 'RS', 'BRL', '+', '-', 'D', 'C'};
}
