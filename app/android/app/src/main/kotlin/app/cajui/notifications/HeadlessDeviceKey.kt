package app.cajui.notifications

import android.content.Context
import android.util.Log
import app.cajui.auth.BiometricGate
import app.cajui.auth.DeviceKey
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * A chave do aparelho no motor sem janela: só a parte pública.
 *
 * O Dart diz ao servidor quem é o aparelho pela chave pública, e isso vale
 * também com o app fechado — a subida do lançamento feito em segundo plano
 * usa o mesmo caminho. Assinar pede a digital, e sem tela não há digital:
 * esse pedido é recusado aqui, e a subida espera o app abrir.
 */
class HeadlessDeviceKey(context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    private val key = DeviceKey()

    init {
        BiometricGate.appContext = context.applicationContext
        MethodChannel(messenger, "app.cajui/device").setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "canAuthenticate" -> result.success(key.canAuthenticate)
                "publicKey" -> result.success(key.publicKey())
                "signQuietly" -> result.success(
                    key.trySign(call.argument<ByteArray>("message") ?: ByteArray(0)),
                )
                else -> result.notImplemented()
            }
        } catch (failure: Exception) {
            Log.w(TAG, "chave do aparelho recusou: ${failure.javaClass.simpleName}")
            result.error("E-AUTH-01", failure.javaClass.simpleName, null)
        }
    }

    private companion object {
        const val TAG = "cajui-notices"
    }
}
