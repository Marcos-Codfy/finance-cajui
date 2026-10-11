package app.cajui.notifications

/**
 * Os apps de banco e de carteira cujas notificações o Cajui lê (ADR-025).
 *
 * O leitor de notificações do Android enxerga tudo o que chega ao celular —
 * conversa, código de acesso, e-mail. O Cajui descarta, sem ler, tudo o que
 * não vem destes pacotes: nem o título de uma notificação de fora da lista
 * chega ao Dart.
 *
 * A mesma lista mora no domínio, em `bank_app.dart`, que é quem sabe ler
 * cada banco. Um teste do app confere que as duas andam juntas.
 */
object BankApps {
    val packages: Set<String> = setOf(
        "com.nu.production",
        "com.mercadopago.wallet",
        "br.com.neon",
        "com.picpay",
        "br.com.intermedium",
        "com.itau",
        "br.com.gabba.Caixa",
        "br.gov.caixa.tem",
        "br.com.bb.android",
        "com.santander.app",
        "com.c6bank.app",
        "com.bradesco",
        "com.google.android.apps.walletnfcrel",
        "com.samsung.android.spay",
    )
}
