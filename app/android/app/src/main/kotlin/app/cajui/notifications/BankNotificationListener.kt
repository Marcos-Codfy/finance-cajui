package app.cajui.notifications

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

/**
 * O leitor das notificações dos bancos (ADR-025).
 *
 * Só existe depois que a pessoa libera, na tela do sistema, o acesso às
 * notificações — e pode ser desligado lá a qualquer momento. Do que chega,
 * fica só o que vem de um banco da lista; o resto é ignorado sem ser lido.
 */
class BankNotificationListener : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        val posted = sbn ?: return
        if (posted.packageName !in BankApps.packages) return
        try {
            val item = NoticeReader.read(posted) ?: return
            if (NoticeQueue(applicationContext).offer(item)) NoticeRouter.kick(applicationContext)
        } catch (failure: Exception) {
            // Só o tipo da falha: o texto da notificação tem valor e nome, e
            // não vai para log nenhum (RN-797).
            Log.w(TAG, "notificação do banco recusada: ${failure.javaClass.simpleName}")
        }
    }

    private companion object {
        const val TAG = "cajui-notices"
    }
}
