package app.cajui.reminders

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * O alarme dos lembretes de vencimento (RN-1081): um só, marcado para o
 * próximo lembrete ainda não mostrado.
 *
 * Inexato de propósito, como o de domingo (`ReviewAlarm`): o Android junta
 * com os de outros apps e acorda o celular menos vezes, e para um aviso de
 * "vence sábado" uns minutos depois das 9h não fazem diferença. Por isso
 * também não há permissão de alarme exato. Lembrete cuja hora já passou —
 * celular desligado, conta cadastrada depois das 9h — chega assim que o
 * alarme roda, desde que o dia do vencimento não tenha acabado (RN-840).
 */
object ReminderAlarm {

    const val ACTION = "app.cajui.action.REMINDER_ALARM"
    private const val REQUEST = 7501

    /** Marca o alarme do próximo lembrete; sem nenhum, desmarca. */
    fun schedule(context: Context) {
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return
        val store = ReminderStore(context)
        val now = System.currentTimeMillis()
        val next = store.items()
            .filter { now < it.expiresAt && !store.wasDelivered(it) }
            .minOfOrNull { it.fireAt }
        val pending = pending(context)
        if (next == null) alarms.cancel(pending) else alarms.set(AlarmManager.RTC_WAKEUP, next, pending)
    }

    /**
     * Mostra os lembretes cuja hora chegou e marca o próximo. No mês com
     * falta, o segundo momento de um vencimento já avisado fica em silêncio
     * (RN-846): é anotado como entregue, sem aparecer.
     */
    fun deliver(context: Context) {
        val store = ReminderStore(context)
        val poster = ReminderPoster(context)
        val now = System.currentTimeMillis()
        store.forgetExpired(now)
        store.items()
            .filter { it.fireAt <= now && now < it.expiresAt && !store.wasDelivered(it) }
            .sortedBy { it.fireAt }
            .forEach { reminder ->
                val silent = reminder.oncePerEvent && store.eventShown(reminder)
                // Entregue fica anotado de qualquer jeito, para não repetir;
                // mostrado, só o que apareceu de fato.
                val shown = !silent && poster.post(reminder)
                store.markDelivered(reminder, shown = shown)
            }
        schedule(context)
    }

    private fun pending(context: Context): PendingIntent {
        val intent = Intent(context, ReminderAlarmReceiver::class.java).setAction(ACTION)
        return PendingIntent.getBroadcast(
            context,
            REQUEST,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }
}

/** A hora chegou: mostra o que venceu de aviso e marca o próximo. */
class ReminderAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ReminderAlarm.ACTION) return
        ReminderAlarm.deliver(context)
    }
}

/**
 * O celular reiniciou, ou o app foi atualizado: o Android esqueceu o
 * alarme, e a lista guardada o marca de novo — sem precisar abrir o app.
 */
class ReminderBootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val known = intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED
        if (known) ReminderAlarm.schedule(context)
    }
}
