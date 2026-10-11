import 'package:domain/src/notifications/notice_text.dart';

/// Os apps de banco e de carteira cujas notificações o Cajui lê (RN-786).
///
/// É uma lista fechada de propósito: o leitor de notificações do Android
/// enxerga **tudo** o que chega ao celular, e o Cajui só olha para o que vem
/// destes pacotes. A mesma lista existe do lado nativo, em `BankApps.kt`, e
/// um teste do app confere que as duas andam juntas.
enum BankApp {
  /// Nubank.
  nubank('Nubank', ['com.nu.production'], ['nubank', 'nu', 'roxinho']),

  /// Mercado Pago.
  mercadoPago(
    'Mercado Pago',
    ['com.mercadopago.wallet'],
    ['mercado pago', 'mercadopago'],
  ),

  /// Neon.
  neon('Neon', ['br.com.neon'], ['neon']),

  /// PicPay.
  picPay('PicPay', ['com.picpay'], ['picpay']),

  /// Banco Inter.
  inter('Inter', ['br.com.intermedium'], ['inter']),

  /// Itaú.
  itau('Itaú', ['com.itau'], ['itau', 'itaucard']),

  /// Caixa, no app do banco e no Caixa Tem.
  caixa('Caixa', ['br.com.gabba.Caixa', 'br.gov.caixa.tem'], ['caixa']),

  /// Banco do Brasil.
  bancoDoBrasil(
    'Banco do Brasil',
    ['br.com.bb.android'],
    ['bb', 'banco do brasil', 'ourocard'],
  ),

  /// Santander.
  santander('Santander', ['com.santander.app'], ['santander']),

  /// C6 Bank.
  c6('C6', ['com.c6bank.app'], ['c6']),

  /// Bradesco.
  bradesco('Bradesco', ['com.bradesco'], ['bradesco']),

  /// Google Wallet: avisa o pagamento por aproximação de qualquer cartão.
  googleWallet('Google Wallet', ['com.google.android.apps.walletnfcrel'], []),

  /// Samsung Wallet, o antigo Samsung Pay.
  samsungWallet('Samsung Wallet', ['com.samsung.android.spay'], []);

  new(this.label, this.packageNames, this._cardWords);

  /// Como a pessoa chama o banco.
  final String label;

  /// Os pacotes Android do app.
  final List<String> packageNames;

  /// As palavras que, no nome de um cartão cadastrado, dizem que ele é deste
  /// banco: "Roxinho" é Nubank, "Ourocard" é Banco do Brasil.
  final List<String> _cardWords;

  /// O app de [packageName]; `null` quando não é banco da lista.
  static BankApp? ofPackage(String packageName) {
    for (final app in values) {
      if (app.packageNames.contains(packageName)) return app;
    }
    return null;
  }

  /// Os pacotes lidos, de cada um dos apps.
  static Set<String> get allPackages => {
    for (final app in values) ...app.packageNames,
  };

  /// Se é carteira, e não banco: a carteira não diz de que banco é o
  /// cartão, só os quatro últimos dígitos.
  bool get isWallet => this == googleWallet || this == samsungWallet;

  /// Se o cartão cadastrado como [cardName] é deste banco. Palavra inteira,
  /// sem caixa nem acento: "Cartão Nubank" é Nubank, "Internet" não é Inter.
  bool namesCard(String cardName) {
    final words = ' ${NoticeText.words(cardName)} ';
    return _cardWords.any((word) => words.contains(' $word '));
  }
}
