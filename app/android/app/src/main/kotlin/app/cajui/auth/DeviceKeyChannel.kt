package app.cajui.auth

import androidx.fragment.app.FragmentActivity
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * A ponte até a chave do aparelho.
 *
 * Três perguntas atravessam: *dá para confirmar quem sou neste aparelho?*,
 * *qual é a sua chave pública?* e *assine isto*. A chave privada não vem — e
 * nem poderia, porque não existe fora do Keystore. A digital também não: quem
 * a lê é o Android, que devolve só a assinatura pronta.
 */
class DeviceKeyChannel(
    private val activity: FragmentActivity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val key = DeviceKey()

    init {
        BiometricGate.appContext = activity.applicationContext
        MethodChannel(messenger, "app.cajui/device").setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "canAuthenticate" -> result.success(key.canAuthenticate)
                "publicKey" -> result.success(key.publicKey())
                "sign" -> sign(call, result)
                "forget" -> result.success(key.forget())
                else -> result.notImplemented()
            }
        } catch (failure: Exception) {
            // A falha do Keystore fica no log do aparelho, que é o único
            // lugar onde dá para diagnosticá-la — não há depurador no
            // celular de quem usa. Só a exceção: nenhum dado da pessoa.
            // Quem fala com ela é o catálogo, pelo código.
            android.util.Log.w(TAG, "chave do aparelho recusou", failure)
            result.error(codeFor(failure), failure::class.java.simpleName, null)
        }
    }

    /**
     * A assinatura sai da caixa de diálogo do sistema, e só de lá. Desistir
     * devolve vazio: a camada de cima entende como "não agora", e não como
     * defeito.
     */
    private fun sign(call: MethodCall, result: MethodChannel.Result) {
        val message = call.argument<ByteArray>("message")!!
        BiometricGate.sign(activity, key.pendingSignature(), message) { signed ->
            result.success(signed)
        }
    }

    /**
     * Três destinos, e nenhum chute.
     *
     * Chave invalidada porque a digital do aparelho mudou é caso à parte: o
     * aparelho precisa se cadastrar de novo, e a chave velha não serve mais.
     * `E-AUTH-01` diz "este aparelho não tem biometria configurada", então
     * só sai quando **for verdade** — antes ele era o destino de qualquer
     * falha, e o aparelho do dono, cheio de digital cadastrada, ouviu que
     * não tinha nenhuma. O resto é defeito nosso, e se chama assim.
     */
    private fun codeFor(failure: Exception): String {
        if (failure is android.security.keystore.KeyPermanentlyInvalidatedException) {
            key.forget()
            return "E-AUTH-03"
        }
        return if (key.canAuthenticate) "E-APP-01" else "E-AUTH-01"
    }

    private companion object {
        const val TAG = "cajui-auth"
    }
}
