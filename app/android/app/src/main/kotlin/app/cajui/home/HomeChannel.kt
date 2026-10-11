package app.cajui.home

import android.content.Context
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * O canal `app.cajui/home` (ADR-025): o Dart publica o retrato, e daqui ele
 * vai para o widget e para o aviso de domingo.
 */
class HomeChannel(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    init {
        MethodChannel(messenger, "app.cajui/home").setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "publish") return result.notImplemented()
        try {
            HomeSnapshotStore(context).save(call.arguments as? Map<*, *> ?: emptyMap<String, Any>())
            HomeWidget.refresh(context)
            // Marcar a cada publicação é o que garante o aviso depois de
            // instalar, sem esperar o celular reiniciar.
            ReviewAlarm.schedule(context)
            result.success(null)
        } catch (failure: Exception) {
            Log.w("cajui-home", "retrato recusado: ${failure.javaClass.simpleName}")
            result.error("E-APP-01", failure.javaClass.simpleName, null)
        }
    }
}
