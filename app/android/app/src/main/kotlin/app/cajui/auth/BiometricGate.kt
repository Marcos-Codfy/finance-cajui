package app.cajui.auth

import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.fragment.app.FragmentActivity
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

    /**
     * "Digital forte, ou o desbloqueio do aparelho" — **na régua desta
     * caixa de diálogo**.
     *
     * É a mesma ideia do `DeviceKey.AUTH_KINDS`, em números diferentes: o
     * Keystore conta em `KeyProperties.AUTH_*` (1 e 2) e o `BiometricPrompt`
     * em `BiometricManager.Authenticators` (0x000F e 0x8000). Trocar uma
     * pela outra compila sem reclamar e só quebra no aparelho, com
     * "Authenticator combination is unsupported" — foi exatamente o que
     * aconteceu no primeiro uso do S22.
     */
    const val PROMPT_KINDS =
        BiometricManager.Authenticators.BIOMETRIC_STRONG or
            BiometricManager.Authenticators.DEVICE_CREDENTIAL

    /** Se dá para liberar a chave neste aparelho: digital, rosto ou PIN. */
    fun isAvailable(): Boolean {
        val manager = BiometricManager.from(appContext ?: return false)
        return manager.canAuthenticate(PROMPT_KINDS) ==
            BiometricManager.BIOMETRIC_SUCCESS
    }

    /** O contexto da atividade em cima, posto pelo canal. */
    var appContext: android.content.Context? = null

    /**
     * Abre a janela de uso da chave, e diz se conseguiu.
     *
     * Não vai objeto de criptografia junto: a chave tem prazo de validade,
     * e quem a libera por esse prazo é o próprio Keystore quando o Android
     * confirma quem está ali. O app não recebe nada além de um "foi" — nem
     * a digital, nem a chave.
     */
    fun unlock(activity: FragmentActivity, onDone: (Boolean) -> Unit) {
        val executor = Executor { command -> activity.runOnUiThread(command) }
        val prompt = BiometricPrompt(
            activity,
            executor,
            object : BiometricPrompt.AuthenticationCallback() {
                override fun onAuthenticationSucceeded(
                    result: BiometricPrompt.AuthenticationResult,
                ) = onDone(true)

                // Desistir não é erro: a pessoa fechou a caixa, e o app volta
                // ao que estava fazendo sem alarde.
                override fun onAuthenticationError(code: Int, message: CharSequence) =
                    onDone(false)
            },
        )
        prompt.authenticate(info())
    }

    private fun info() = BiometricPrompt.PromptInfo.Builder()
        .setTitle("Confirme que é você")
        .setSubtitle("O Cajui vai falar com o seu servidor")
        .setAllowedAuthenticators(PROMPT_KINDS)
        .build()
}
