import 'package:domain/src/ledger/possible_duplicate.dart';
import 'package:domain/src/receipts/merchant_kind.dart';
import 'package:meta/meta.dart';

/// A marca por trás do jeito como o extrato escreve (RN-1108).
///
/// O extrato escreve a plataforma, e não o restaurante: "IFD*RESTAURANTE
/// SABOR" é um pedido no iFood. Para a pessoa a compra é "iFood", e é por
/// esse nome que a memória (RN-1116) a reconhece no mês seguinte — cada
/// restaurante viraria uma chave diferente. A tabela é literal (RN-733): o
/// nome que aparece é sempre o daqui, nunca o texto do extrato.
@immutable
final class MerchantBrand {
  const new _(this.name, this.kind);

  /// O nome como a pessoa conhece: "iFood".
  final String name;

  /// O ramo; o que ele vira de categoria é escolha do cadastro de quem usa.
  final MerchantKind kind;

  /// A marca de [written], ou `null` quando não é nenhuma conhecida.
  static MerchantBrand? of(String written) {
    final upper = written.toUpperCase();
    for (final (marks, brand) in _brands) {
      if (marks.any(upper.contains)) return brand;
    }
    return null;
  }

  /// [written] sem o prefixo da maquininha: "MP*PADARIA BOA VISTA" é a
  /// Padaria Boa Vista. O prefixo só sai no começo de uma palavra.
  static String withoutAcquirer(String written) {
    var text = written;
    for (final prefix in _acquirers) {
      final at = text.toUpperCase().indexOf(prefix);
      if (at < 0 || (at > 0 && text[at - 1] != ' ')) continue;
      text = text.replaceRange(at, at + prefix.length, ' ');
    }
    return text.trim().replaceAll(RegExp(' +'), ' ');
  }

  /// A chave do estabelecimento (RN-1116): a da marca, ou o nome
  /// normalizado (RN-727) sem a maquininha.
  static String keyOf(String written) => PossibleDuplicate.normalize(
    of(written)?.name ?? withoutAcquirer(written),
  );

  /// Uber Eats vem antes de Uber: as duas começam igual, e a de entrega é
  /// a mais específica.
  static const _brands = <(List<String>, MerchantBrand)>[
    (
      ['UBER *EATS', 'UBER* EATS', 'UBER EATS', 'UBEREATS'],
      MerchantBrand._('Uber Eats', MerchantKind.delivery),
    ),
    (['IFD*', 'IFOOD'], MerchantBrand._('iFood', MerchantKind.delivery)),
    (['RAPPI'], MerchantBrand._('Rappi', MerchantKind.delivery)),
    (
      ['ZE DELIVERY', 'ZEDELIVERY'],
      MerchantBrand._('Zé Delivery', MerchantKind.delivery),
    ),
    (
      ['UBER *', 'UBER*', 'UBER TRIP', 'UBERTRIP', 'UBER DO BRASIL'],
      MerchantBrand._('Uber', MerchantKind.rideHailing),
    ),
    (
      ['99APP', '99 APP', '99 TECNOLOGIA', '99TECNOLOGIA', '99 POP', '99POP'],
      MerchantBrand._('99', MerchantKind.rideHailing),
    ),
    (['NETFLIX'], MerchantBrand._('Netflix', MerchantKind.streaming)),
    (['SPOTIFY'], MerchantBrand._('Spotify', MerchantKind.streaming)),
    (
      ['APPLE.COM/BILL', 'APPLE.COM BILL', 'APPLE COM BILL'],
      MerchantBrand._('Apple', MerchantKind.streaming),
    ),
    (
      ['GOOGLE *YOUTUBE', 'GOOGLE YOUTUBE', 'YOUTUBE PREMIUM'],
      MerchantBrand._('YouTube', MerchantKind.streaming),
    ),
    (
      ['PRIME VIDEO', 'PRIMEVIDEO', 'AMAZON PRIME', 'AMAZONPRIME'],
      MerchantBrand._('Prime Video', MerchantKind.streaming),
    ),
    (
      ['DISNEY PLUS', 'DISNEYPLUS', 'DISNEY+'],
      MerchantBrand._('Disney+', MerchantKind.streaming),
    ),
    (['HBO MAX', 'HBOMAX'], MerchantBrand._('Max', MerchantKind.streaming)),
    (['GLOBOPLAY'], MerchantBrand._('Globoplay', MerchantKind.streaming)),
  ];

  /// Os prefixos das maquininhas, do mais longo para o mais curto, para
  /// "MERCADOPAGO*" sair inteiro antes de "MP*" ser procurado.
  static const _acquirers = [
    'MERCADOPAGO *',
    'MERCADOPAGO*',
    'PAGSEGURO *',
    'PAGSEGURO*',
    'MERCPAGO*',
    'PICPAY *',
    'PICPAY*',
    'SUMUP *',
    'SUMUP*',
    'STONE *',
    'STONE*',
    'PAG *',
    'PAG*',
    'TON *',
    'TON*',
    'MP *',
    'MP*',
    'EC *',
  ];
}
