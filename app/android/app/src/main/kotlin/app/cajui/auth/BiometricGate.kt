package app.cajui.auth

import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.fragment.app.FragmentActivity
import java.security.KeyStore
import java.security.Signature
import java.util.concurrent.Executor

/**
 * A porta que o Android abre, e o Cajui não.
 *
 * Quem desenha a caixa de diálogo, lê a digital e decide se é você é o
 * sistema. O app entrega uma assinatura pela metade e recebe de volta a
 * mesma coisa, liberada — **nunca vê a digital nem a chave**. É essa divisão
 * que faz a biometria valer alguma coisa aqui: não há nada no app para um
 * atacante enganar.
 */
object BiometricGate {

    /** Se dá para liberar a chave neste aparelho: digital, rosto ou PIN. */
    fun isAvailable(keyStore: KeyStore): Boolean {
        val manager = BiometricManager.from(appContext ?: return false)
        return manager.canAuthenticate(DeviceKey.AUTH_KINDS) ==
            BiometricManager.BIOMETRIC_SUCCESS
    }

    /** O contexto da atividade em cima, posto pelo canal. */
    var appContext: android.content.Context? = null

    /**
     * Pede a confirmação e devolve a assinatura de [message], ou `null` se a
     * pessoa desistiu.
     */
    fun sign(
        activity: FragmentActivity,
        pending: Signature,
        message: ByteArray,
        onDone: (ByteArray?) -> Unit,
    ) {
        val executor = Executor { command -> activity.runOnUiThread(command) }
        val prompt = BiometricPrompt(
            activity,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(
                    result: BiometricPrompt.AuthenticationResult,
                ) {
                    val signature = result.cryptoObject?.signature
                    if (signature == null) {
                        onDone(null)
                        return
                    }
                    signature.update(message)
                    onDone(signature.sign())
                }

                // Desistir não é erro: a pessoa fechou a caixa, e o app volta
                // ao que estava fazendo sem alarde.
                override fun onAuthenticationError(code: Int, message: CharSequence) =
                    onDone(null)
            },
        )
        prompt.authenticate(info(), BiometricPrompt.CryptoObject(pending))
    }

    private fun info() = BiometricPrompt.PromptInfo.Builder()
        .setTitle("Confirme que é você")
        .setSubtitle("O Cajui vai falar com o seu servidor")
        .setAllowedAuthenticators(DeviceKey.AUTH_KINDS)
        .build()
}
