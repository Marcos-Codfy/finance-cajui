package app.cajui.notifications

import android.Manifest
import android.app.Activity
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

/**
 * As duas permissões de que o lançamento pelas notificações precisa, e que
 * só a pessoa dá (ADR-025): ler as notificações dos outros apps, numa tela
 * do sistema; e postar as do Cajui, a partir do Android 13.
 */
object NotificationAccess {

    /** O código do pedido de permissão para postar, que volta à atividade. */
    const val REQUEST_POST = 7301

    /** Se a pessoa liberou o acesso às notificações para o Cajui. */
    fun isGranted(context: Context): Boolean =
        NotificationManagerCompat.getEnabledListenerPackages(context).contains(context.packageName)

    /**
     * Primeiro a permissão de postar — sem ela, o "Lancei R$ 45,90. Desfazer?"
     * não aparece, e lançar sem avisar não é o combinado. Quando ela já foi
     * dada, ou o Android é anterior ao 13, vai direto à tela do sistema.
     */
    fun open(activity: Activity) {
        if (needsPostPermission(activity)) {
            ActivityCompat.requestPermissions(
                activity,
                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                REQUEST_POST,
            )
            return
        }
        openListenerSettings(activity)
    }

    /** A resposta ao pedido de postar: dada ou não, segue para a tela do sistema. */
    fun onPermissionResult(activity: Activity, requestCode: Int) {
        if (requestCode == REQUEST_POST) openListenerSettings(activity)
    }

    private fun needsPostPermission(context: Context): Boolean =
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED

    /**
     * Do Android 11 em diante, a tela abre já no Cajui; antes, na lista de
     * apps com acesso.
     */
    private fun openListenerSettings(activity: Activity) {
        val component = ComponentName(activity, BankNotificationListener::class.java)
        val detail = Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS)
            .putExtra(Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME, component.flattenToString())
        val list = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        val useDetail = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R &&
            detail.resolveActivity(activity.packageManager) != null
        activity.startActivity(if (useDetail) detail else list)
    }
}
