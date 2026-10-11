package app.cajui.home

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import app.cajui.notifications.NoticePoster
import java.util.Calendar

/**
 * O aviso de domingo da revisão da semana (RN-870), perto das 10h.
 *
 * Alarme **inexato** de propósito: o Android junta com os de outros apps e
 * acorda o celular menos vezes, e para um aviso de "confere em 1 minuto" uns
 * minutos a mais não fazem diferença. Por isso também não há permissão de
 * alarme exato. O alarme não sobrevive a reiniciar o celular: [BootReceiver]
 * o marca de novo, e cada publicação do app também.
 */
object ReviewAlarm {

    const val ACTION = "app.cajui.action.REVIEW_ALARM"
    private const val REQUEST = 7402
    private const val HOUR = 10

    /** Marca o próximo domingo às 10h — o de hoje, se ainda não passou. */
    fun schedule(context: Context) {
        val alarms = context.getSystemService(AlarmManager::class.java) ?: return
        val intent = Intent(context, ReviewAlarmReceiver::class.java).setAction(ACTION)
        val pending = PendingIntent.getBroadcast(
            context,
            REQUEST,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        alarms.set(AlarmManager.RTC_WAKEUP, nextSunday(Calendar.getInstance()), pending)
    }

    /** O próximo domingo às 10h depois de [now], no fuso do aparelho. */
    fun nextSunday(now: Calendar): Long {
        val next = (now.clone() as Calendar).apply {
            set(Calendar.HOUR_OF_DAY, HOUR)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            val days = (Calendar.SUNDAY - get(Calendar.DAY_OF_WEEK) + 7) % 7
            add(Calendar.DAY_OF_YEAR, days)
        }
        if (!next.after(now)) next.add(Calendar.DAY_OF_YEAR, 7)
        return next.timeInMillis
    }
}

/**
 * Domingo chegou: avisa se há o que revisar, e marca o próximo. Sem nada
 * para revisar, nenhum aviso (RN-870).
 */
class ReviewAlarmReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ReviewAlarm.ACTION) return
        val count = HomeSnapshotStore(context).reviewCount()
        if (count > 0) NoticePoster(context).review(count)
        ReviewAlarm.schedule(context)
    }
}

/**
 * O celular reiniciou, ou o app foi atualizado: os alarmes se perderam, e o
 * de domingo é marcado de novo — se o app já foi aberto alguma vez.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val known = intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED
        if (!known || !HomeSnapshotStore(context).exists) return
        ReviewAlarm.schedule(context)
        HomeWidget.refresh(context)
    }
}
