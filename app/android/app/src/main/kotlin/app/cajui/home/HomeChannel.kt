package app.cajui.home

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.os.Build
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * O canal `app.cajui/home` (ADR-025): o Dart publica o retrato, e daqui ele
 * vai para o widget e para o aviso de domingo. Também diz se o widget já
 * está na tela inicial e pede ao launcher para pô-lo lá.
 */
class HomeChannel(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    init {
        MethodChannel(messenger, "app.cajui/home").setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "publish" -> publish(call, result)
            "placement" -> result.success(placement())
            "pin" -> result.success(pin())
            else -> result.notImplemented()
        }
    }

    private fun publish(call: MethodCall, result: MethodChannel.Result) {
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

    /**
     * "placed" se já há um widget do Cajui na tela; "absent" se o launcher
     * aceita o pedido do app (Android 8 em diante, e nem todo launcher);
     * "manual" se só dá pelo menu de widgets.
     */
    private fun placement(): String {
        val manager = AppWidgetManager.getInstance(context)
        return when {
            manager.getAppWidgetIds(widget()).isNotEmpty() -> "placed"
            canPin(manager) -> "absent"
            else -> "manual"
        }
    }

    /**
     * Pede ao launcher. O sistema mostra a confirmação com a prévia, e é a
     * pessoa quem decide; o widget novo se desenha sozinho com o último
     * retrato publicado.
     */
    private fun pin(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return false
        val manager = AppWidgetManager.getInstance(context)
        if (!manager.isRequestPinAppWidgetSupported) return false
        return manager.requestPinAppWidget(widget(), null, null)
    }

    private fun canPin(manager: AppWidgetManager): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && manager.isRequestPinAppWidgetSupported

    private fun widget() = ComponentName(context, HomeWidget::class.java)
}
