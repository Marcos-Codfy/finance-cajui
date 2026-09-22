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
            result.error(codeFor(failure), null, null)
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
     * Chave invalidada porque a digital do aparelho mudou é caso à parte: o
     * aparelho precisa se cadastrar de novo, e a chave velha não serve mais.
     */
    private fun codeFor(failure: Exception): String {
        val invalidated = failure is android.security.keystore.KeyPermanentlyInvalidatedException
        if (invalidated) key.forget()
        return if (invalidated) "E-AUTH-03" else "E-AUTH-01"
    }
}
