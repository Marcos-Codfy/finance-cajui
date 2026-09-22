package app.cajui.auth

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.Signature
import java.security.spec.ECGenParameterSpec

/**
 * A identidade deste aparelho perante o servidor (ADR-008).
 *
 * A chave privada nasce **dentro do Keystore do Android** e nunca sai de lá:
 * o app pede assinaturas, não a chave. Em aparelho com StrongBox — o S22 tem
 * —, ela vive no elemento seguro, fora do alcance até de quem tenha o celular
 * desbloqueado na mão.
 *
 * É por isso que não existe senha nem token guardado no app: quem prova quem
 * é somos nós assinando um desafio do servidor, e só o Keystore consegue
 * assinar.
 */
class DeviceKey {

    /** A chave pública em X.509 DER, que é o formato que o servidor espera. */
    fun publicKey(): ByteArray = keyPair().let { it.certificate.publicKey.encoded }

    /** Assina [message] com SHA-256/ECDSA; a assinatura sai em DER. */
    fun sign(message: ByteArray): ByteArray {
        val entry = keyPair()
        return Signature.getInstance("SHA256withECDSA").run {
            initSign(entry.privateKey as java.security.PrivateKey)
            update(message)
            sign()
        }
    }

    /** A entrada do Keystore, criada na primeira vez e reusada depois. */
    private fun keyPair(): KeyStore.PrivateKeyEntry {
        val store = KeyStore.getInstance(PROVIDER).apply { load(null) }
        (store.getEntry(ALIAS, null) as? KeyStore.PrivateKeyEntry)?.let { return it }
        generate()
        return store.getEntry(ALIAS, null) as KeyStore.PrivateKeyEntry
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

    private companion object {
        const val PROVIDER = "AndroidKeyStore"
        const val ALIAS = "cajui-device-key"
    }
}
