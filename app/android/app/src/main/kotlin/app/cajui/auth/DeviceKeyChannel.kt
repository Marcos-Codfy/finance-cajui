package app.cajui.auth

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * A ponte até o nome do aparelho, pelo canal `app.cajui/device`.
 *
 * Uma pergunta só atravessa: *qual é a sua chave pública?* Assinar, pedir
 * a digital e apagar a chave saíram com a ADR-024 — quem entra no servidor
 * é a chave da casa, e o Dart já não pedia nada disso.
 */
class DeviceKeyChannel(messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {

    private val key = DeviceKey()

    init {
        MethodChannel(messenger, "app.cajui/device").setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "publicKey") {
            result.notImplemented()
            return
        }
        try {
            result.success(key.publicKey())
        } catch (failure: Exception) {
            // A falha do Keystore fica no log do aparelho, que é o único
            // lugar onde dá para diagnosticá-la. Só a exceção: nenhum dado
            // da pessoa. O Dart, sem a chave, fala com o servidor com um
            // nome genérico — e sincroniza do mesmo jeito.
            android.util.Log.w(TAG, "chave do aparelho recusou", failure)
            result.error("E-APP-01", failure::class.java.simpleName, null)
        }
    }

    private companion object {
        const val TAG = "cajui-auth"
    }
}
