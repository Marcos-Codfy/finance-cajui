package app.cajui.auth

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * A ponte até a chave do aparelho.
 *
 * Só duas perguntas atravessam: "qual é a sua chave pública?" e "assine
 * isto". A chave privada não tem como vir — o Dart nunca a vê, e nem
 * poderia: ela não existe fora do Keystore.
 */
class DeviceKeyChannel(messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {

    private val key = DeviceKey()

    init {
        MethodChannel(messenger, "app.cajui/device").setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "publicKey" -> result.success(key.publicKey())
                "sign" -> result.success(key.sign(call.argument<ByteArray>("message")!!))
                else -> result.notImplemented()
            }
        } catch (failure: Exception) {
            // Keystore indisponível, ou chave apagada por troca da tela de
            // bloqueio: para o app, este aparelho não consegue se confirmar
            // agora — que é exatamente o que o `E-AUTH-03` diz.
            result.error("E-AUTH-03", null, null)
        }
    }
}
