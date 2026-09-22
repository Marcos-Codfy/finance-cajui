/// O ramo do estabelecimento, deduzido do nome dele.
///
/// Serve para propor a categoria quando ninguém ensinou nada ainda: um cupom
/// de supermercado é compra de mercado antes de qualquer IA opinar. O que
/// cada ramo vira de categoria é escolha do cadastro de quem usa, e não do
/// domínio — aqui só se lê o ramo.
enum MerchantKind {
  /// Supermercado, hipermercado, atacarejo, mercearia.
  supermarket,

  /// Feira livre.
  streetMarket,

  /// Hortifrúti, sacolão, quitanda.
  produce,

  /// Açougue, casa de carnes, frigorífico.
  butcher,

  /// Padaria e panificadora.
  bakery,

  /// Restaurante, lanchonete, pizzaria, bar, cafeteria.
  dining,

  /// Farmácia e drogaria.
  pharmacy,

  /// Posto de combustível.
  fuel,
}
