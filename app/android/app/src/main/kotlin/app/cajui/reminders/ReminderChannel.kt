package app.cajui.reminders

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * O canal `app.cajui/reminders` (RN-1081, RN-1088): o Dart publica a lista
 * dos lembretes, e daqui ela vai para o armazenamento e para o alarme.
 * Também diz se o Cajui pode notificar e pede a permissão.
 */
class ReminderChannel(
    private val context: Context,
    messenger: BinaryMessenger,
    private val activity: Activity?,
) : MethodChannel.MethodCallHandler {

    init {
        MethodChannel(messenger, NAME).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "replace" -> replace(call, result)
                "canPost" -> result.success(NotificationManagerCompat.from(context).areNotificationsEnabled())
                "allowPosting" -> allowPosting(result)
                else -> result.notImplemented()
            }
        } catch (failure: Exception) {
            // Só o tipo: o que atravessa este canal tem valor e nome.
            Log.w(TAG, "lembretes recusados: ${failure.javaClass.simpleName}")
            result.error("E-APP-01", failure.javaClass.simpleName, null)
        }
    }

    /**
     * Troca a lista, tira da bandeja o que saiu dela e remarca o alarme —
     * a cada publicação, o que também cobre o app recém-instalado.
     */
    private fun replace(call: MethodCall, result: MethodChannel.Result) {
        val items = call.argument<List<Map<*, *>>>("items").orEmpty()
        val reminders = items.mapNotNull(Reminder::fromMap)
        ReminderStore(context).replace(reminders)
        ReminderPoster(context).withdrawAllBut(reminders)
        ReminderAlarm.schedule(context)
        result.success(null)
    }

    /**
     * Do Android 13 em diante, a primeira vez é a pergunta do sistema; se a
     * pessoa já disse não, o sistema não pergunta de novo, e o caminho é a
     * tela de notificações do Cajui nos ajustes do Android.
     */
    private fun allowPosting(result: MethodChannel.Result) {
        val host = activity
        if (host != null) {
            if (shouldAsk(host)) ask(host) else openSettings(host)
        }
        result.success(null)
    }

    private fun shouldAsk(host: Activity): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return false
        val granted = ContextCompat.checkSelfPermission(host, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        val asked = host.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).getBoolean(ASKED, false)
        return !granted && !asked
    }

    private fun ask(host: Activity) {
        host.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE).edit().putBoolean(ASKED, true).apply()
        ActivityCompat.requestPermissions(host, arrayOf(Manifest.permission.POST_NOTIFICATIONS), REQUEST_POST)
    }

    private fun openSettings(host: Activity) {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, host.packageName)
        } else {
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", host.packageName, null))
        }
        host.startActivity(intent)
    }

    companion object {
        /** O nome do canal: o contrato com `native_reminder_schedule.dart`. */
        const val NAME = "app.cajui/reminders"

        /** Diferente do pedido das notificações do banco, que segue para outra tela. */
        private const val REQUEST_POST = 7502
        private const val PREFERENCES = "cajui.reminders.permission"
        private const val ASKED = "asked"
        private const val TAG = "cajui-reminders"
    }
}
