package app.cajui.settings

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * O canal `app.cajui/settings`: abre telas do Android que o app indica
 * como saída de um erro — hoje, o armazenamento do `E-STORAGE-01`.
 */
class SettingsChannel(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    init {
        MethodChannel(messenger, "app.cajui/settings").setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "openStorage" -> result.success(openStorage())
            else -> result.notImplemented()
        }
    }

    /** Fabricante que tirou a tela de armazenamento cai nos ajustes gerais. */
    private fun openStorage(): Boolean =
        open(Settings.ACTION_INTERNAL_STORAGE_SETTINGS) || open(Settings.ACTION_SETTINGS)

    private fun open(action: String): Boolean = try {
        context.startActivity(Intent(action).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        true
    } catch (missing: ActivityNotFoundException) {
        false
    }
}
