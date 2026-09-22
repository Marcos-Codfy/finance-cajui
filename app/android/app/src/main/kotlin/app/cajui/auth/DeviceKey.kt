package app.cajui.auth

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.PrivateKey
import java.security.Signature
import java.security.spec.ECGenParameterSpec

/**
 * A identidade deste aparelho perante o servidor (ADR-008).
 *
 * A chave privada nasce **dentro do Keystore do Android** e nunca sai de lá:
 * o app pede assinaturas, não a chave. Em aparelho com StrongBox — o S22 tem
 * —, ela vive no elemento seguro.
 *
 * E ela só assina **com você presente**: a chave é criada exigindo
 * autenticação do usuário a cada uso. Quem libera é o Android, com a digital
 * ou o desbloqueio do aparelho; o Cajui nunca vê a digital, só recebe de
 * volta uma assinatura pronta. Sem isso, um celular perdido e desbloqueado
 * conversaria com o servidor como se fosse você.
 *
 * Trocar a digital cadastrada no aparelho **invalida a chave**
 * (`setInvalidatedByBiometricEnrollment`): é a garantia de que ninguém
 * cadastra a própria digital no seu celular para virar você.
 */
class DeviceKey {

    /** Se o aparelho tem como liberar a chave: digital, rosto ou PIN. */
    val canAuthenticate: Boolean
        get() = BiometricGate.isAvailable()

    /** A chave pública em X.509 DER, que é o formato que o servidor espera. */
    fun publicKey(): ByteArray = entry().certificate.publicKey.encoded

    /**
     * Uma assinatura pela metade: o objeto que o Android vai liberar depois
     * de confirmar quem está ali. Só depois de liberado ele assina.
     */
    fun pendingSignature(): Signature = Signature.getInstance(ALGORITHM).apply {
        initSign(entry().privateKey as PrivateKey)
    }

    /** Apaga a chave. O aparelho vira desconhecido e precisa cadastrar-se. */
    fun forget() = keyStore().deleteEntry(ALIAS)

    private fun keyStore(): KeyStore =
        KeyStore.getInstance(PROVIDER).apply { load(null) }

    private fun entry(): KeyStore.PrivateKeyEntry {
        val store = keyStore()
        (store.getEntry(ALIAS, null) as? KeyStore.PrivateKeyEntry)?.let { return it }
        generate()
        return keyStore().getEntry(ALIAS, null) as KeyStore.PrivateKeyEntry
    }

    private fun generate() {
        val spec = KeyGenParameterSpec.Builder(ALIAS, KeyProperties.PURPOSE_SIGN)
            .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
            .setDigests(KeyProperties.DIGEST_SHA256)
            // Zero segundos: a liberação vale para **um uso**, e não por um
            // tempo. Cada assinatura pede você de novo.
            .setUserAuthenticationRequired(true)
            .setUserAuthenticationParameters(0, AUTH_KINDS)
            .setInvalidatedByBiometricEnrollment(true)
            .build()
        KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, PROVIDER).run {
            initialize(spec)
            generateKeyPair()
        }
    }

    companion object {
        /** O apelido da chave. O `v2` marca a que exige autenticação. */
        const val ALIAS = "cajui-device-key-v2"
        const val PROVIDER = "AndroidKeyStore"
        const val ALGORITHM = "SHA256withECDSA"

        /**
         * Digital e rosto fortes, **ou** o desbloqueio do aparelho. O PIN
         * entra de propósito: sem ele, quem não cadastrou digital ficaria de
         * fora do próprio app.
         *
         * Vale só para **criar a chave**. A caixa de diálogo conta os mesmos
         * fatores em outra escala — ver `BiometricGate.PROMPT_KINDS`.
         */
        const val AUTH_KINDS =
            KeyProperties.AUTH_BIOMETRIC_STRONG or KeyProperties.AUTH_DEVICE_CREDENTIAL
    }
}
