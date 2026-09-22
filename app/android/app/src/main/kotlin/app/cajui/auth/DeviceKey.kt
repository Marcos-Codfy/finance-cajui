package app.cajui.auth

import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.KeyPairGenerator
import java.security.KeyStore
import android.security.keystore.UserNotAuthenticatedException
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
 * E ela só assina **depois de você se confirmar**: a chave é criada exigindo
 * autenticação do usuário, com validade de um dia ([VALIDITY_SECONDS]). Quem
 * libera é o Android, com a digital ou o desbloqueio do aparelho; o Cajui
 * nunca vê a digital, só recebe de volta uma assinatura pronta. Quem conta o
 * prazo é o hardware — o app não tem como esticá-lo.
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
     * Assina [message], **se a janela de autenticação ainda estiver aberta**.
     *
     * Devolve `null` quando o Android diz que ninguém se confirmou dentro do
     * prazo: aí quem chama abre a caixa de diálogo e tenta de novo. É o
     * Keystore que conta o tempo, e não o app — não há relógio de mentira
     * que estique essa janela.
     */
    fun trySign(message: ByteArray): ByteArray? = try {
        Signature.getInstance(ALGORITHM).run {
            initSign(entry().privateKey as PrivateKey)
            update(message)
            sign()
        }
    } catch (_: UserNotAuthenticatedException) {
        null
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
            // A liberação vale por um dia. Quem guarda o prazo é o hardware:
            // passado ele, a chave simplesmente não assina, e o Android pede
            // você de novo.
            .setUserAuthenticationRequired(true)
            .setUserAuthenticationParameters(VALIDITY_SECONDS, AUTH_KINDS)
            .setInvalidatedByBiometricEnrollment(true)
            .build()
        KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, PROVIDER).run {
            initialize(spec)
            generateKeyPair()
        }
    }

    companion object {
        /** O apelido da chave. O `v3` marca a de janela diária. */
        const val ALIAS = "cajui-device-key-v3"

        /**
         * Um dia. É o equilíbrio pedido: confirmar quem é uma vez por dia,
         * e não a cada vez que o app fala com o servidor.
         *
         * O que se perde: um celular roubado **e desbloqueado** dentro da
         * janela conversaria com o servidor. O que se ganha: a pessoa usa o
         * app sem ser interrompida, e quem não é interrompido não desliga a
         * proteção. O prazo é do hardware, não do app.
         */
        const val VALIDITY_SECONDS = 24 * 60 * 60
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
