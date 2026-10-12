package app.cajui.reminders

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import app.cajui.MainActivity
import app.cajui.R

/**
 * Mostra os lembretes de vencimento no canal "Contas a vencer" (RN-1085).
 *
 * O texto vem pronto do Dart. Na tela bloqueada aparece só a versão pública
 * — "Uma conta vence sábado, 10" —, sem nome e sem valor (RN-843); o resto,
 * depois do desbloqueio. O toque abre a tela do assunto (RN-1087).
 */
class ReminderPoster(private val context: Context) {

    private val manager = NotificationManagerCompat.from(context)

    /**
     * Mostra [reminder] e diz se ele apareceu de fato. Sem permissão de
     * notificar, com o canal "Contas a vencer" desligado ou recusado pelo
     * sistema, não aparece — e quem chama não pode contá-lo como mostrado:
     * no mês com falta, o aviso do dia seria calado por um que ninguém viu
     * (RN-1086).
     */
    fun post(reminder: Reminder): Boolean {
        if (!manager.areNotificationsEnabled()) return false
        ensureChannel()
        if (channelOff()) return false
        return try {
            manager.notify(TAG, reminder.notificationId, build(reminder))
            true
        } catch (denied: SecurityException) {
            false
        }
    }

    /** Se a pessoa desligou o canal dos lembretes nas configurações. */
    private fun channelOff(): Boolean =
        android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O &&
            manager.getNotificationChannel(CHANNEL)?.importance ==
            NotificationManager.IMPORTANCE_NONE

    /**
     * Tira da bandeja os lembretes que não estão mais em [current]: a conta
     * paga, a chave desligada, o vencimento que passou. Lembrete que fica
     * na bandeja depois de pago vira cobrança.
     */
    fun withdrawAllBut(current: List<Reminder>) {
        val system = context.getSystemService(NotificationManager::class.java) ?: return
        val keep = current.map { it.notificationId }.toSet()
        system.activeNotifications
            .filter { it.tag == TAG && it.id !in keep }
            .forEach { manager.cancel(TAG, it.id) }
    }

    private fun build(reminder: Reminder): Notification {
        val hidden = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_cajui)
            .setContentTitle(reminder.publicTitle)
            .setContentText(reminder.publicText)
            .build()
        return NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_cajui)
            .setColor(context.getColor(R.color.cajui_accent))
            .setContentTitle(reminder.title)
            .setContentText(reminder.text)
            .setStyle(NotificationCompat.BigTextStyle().bigText(reminder.text))
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
            .setPublicVersion(hidden)
            .setContentIntent(open(reminder))
            .setAutoCancel(true)
            .build()
    }

    /** O toque abre o app já pedindo a tela do assunto. */
    private fun open(reminder: Reminder): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .setAction(ACTION_OPEN)
            .putExtra(EXTRA_ROUTE, reminder.route)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(context, reminder.notificationId, intent, FLAGS)
    }

    /**
     * Canal próprio, em prioridade baixa, sem som nem vibração: o lembrete
     * informa, não interrompe (RN-825). Tem chave própria nos ajustes do
     * Android, separada da revisão de domingo.
     */
    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val system = context.getSystemService(NotificationManager::class.java) ?: return
        val channel = NotificationChannel(
            CHANNEL,
            context.getString(R.string.channel_reminders),
            NotificationManager.IMPORTANCE_LOW,
        ).apply { description = context.getString(R.string.channel_reminders_description) }
        system.createNotificationChannel(channel)
    }

    companion object {
        /** A ação da intenção que o toque manda para a `MainActivity`. */
        const val ACTION_OPEN = "app.cajui.action.REMINDER"

        /** A tela pedida, no formato do Dart: `reminder:bills`. */
        const val EXTRA_ROUTE = "app.cajui.extra.ROUTE"

        private const val CHANNEL = "cajui.reminders"
        private const val TAG = "cajui.reminder"
        private const val ROUTE_PREFIX = "reminder:"
        private const val FLAGS = PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT

        /**
         * A tela que [intent] pede, se ela é de um lembrete. A atividade é
         * exportada: qualquer app pode mandar esta ação, e por isso só passa
         * rota de lembrete — o Dart ainda confere o assunto.
         */
        fun routeOf(intent: Intent?): String? =
            intent?.getStringExtra(EXTRA_ROUTE)?.takeIf { it.startsWith(ROUTE_PREFIX) }
    }
}
