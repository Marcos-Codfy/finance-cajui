package app.cajui.auth

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.GeneralSecurityException
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.spec.ECGenParameterSpec

/**
 * O nome deste aparelho perante o servidor: a chave pública de um par
 * guardado no Keystore do Android.
 *
 * Já não prova nada — quem prova é a chave da casa (ADR-020) — e por isso
 * não assina mais nada (ADR-024). Ficou por um motivo só: é dela que sai o
 * identificador que separa a conversa de cada celular com a assistente, e
 * os celulares do dono já tinham esse identificador. Trocar por outro
 * daria a eles um nome novo sem ganho nenhum.
 *
 * O par antigo, criado exigindo a digital para assinar, continua servindo:
 * ler a chave pública nunca pediu digital. O par novo, de quem instala
 * agora, nasce sem essa exigência — não há o que liberar.
 */
class DeviceKey {

    /** A chave pública em X.509 DER. */
    fun publicKey(): ByteArray = entry().certificate.publicKey.encoded

    private fun keyStore(): KeyStore =
        KeyStore.getInstance(PROVIDER).apply { load(null) }

    private fun entry(): KeyStore.PrivateKeyEntry {
        existing()?.let { return it }
        generate()
        return keyStore().getEntry(ALIAS, null) as KeyStore.PrivateKeyEntry
    }

    /**
     * O par que já está no Keystore, se ainda se lê. O par antigo exigia a
     * digital e morria quando ela mudava; antes quem o recriava era a
     * assinatura, que saiu. Sem isto, o aparelho com o par morto ficaria
     * para sempre com o nome genérico — com um par novo, ganha um nome
     * novo e segue sincronizando do mesmo jeito.
     */
    private fun existing(): KeyStore.PrivateKeyEntry? = try {
        keyStore().getEntry(ALIAS, null) as? KeyStore.PrivateKeyEntry
    } catch (_: GeneralSecurityException) {
        keyStore().deleteEntry(ALIAS)
        null
    }

    private fun generate() {
        val spec = KeyGenParameterSpec.Builder(ALIAS, KeyProperties.PURPOSE_SIGN)
            .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
            .setDigests(KeyProperties.DIGEST_SHA256)
            .build()
        KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, PROVIDER).run {
            initialize(spec)
            generateKeyPair()
        }
    }

    companion object {
        /**
         * O apelido do par. É o mesmo de antes de propósito: os celulares
         * que já tinham o par continuam com o mesmo nome no servidor.
         */
        const val ALIAS = "cajui-device-key-v3"
        const val PROVIDER = "AndroidKeyStore"
    }
}
