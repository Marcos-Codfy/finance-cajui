package app.cajui.notifications

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
 * Posta as notificações do Cajui (ADR-025). O texto vem pronto do Dart —
 * a voz do app mora lá —, a não ser o da revisão de domingo, que nasce sem
 * Dart nenhum rodando e mora em `strings.xml`.
 */
class NoticePoster(private val context: Context) {

    private val manager = NotificationManagerCompat.from(context)

    /** O aviso que o Dart pediu: lançamento feito, ou toque para registrar. */
    fun announce(arguments: Map<*, *>) {
        val title = arguments["title"] as? String ?: return
        val text = arguments["text"] as? String ?: return
        when (arguments["kind"]) {
            "recorded" -> recorded(arguments["entryId"] as? String ?: return, title, text)
            "ask" -> ask(
                arguments["id"] as? String ?: return,
                arguments["shareText"] as? String ?: return,
                title,
                text,
            )
        }
    }

    /** "Lancei R$ 45,90 em Mercado" — com o botão Desfazer (RN-786). */
    private fun recorded(entryId: String, title: String, text: String) {
        val undo = PendingIntent.getBroadcast(
            context,
            entryId.hashCode(),
            Intent(context, UndoReceiver::class.java)
                .setAction(UndoReceiver.ACTION)
                .putExtra(UndoReceiver.EXTRA_ENTRY, entryId),
            FLAGS,
        )
        val notification = base(AUTO_CHANNEL, title, text)
            .setContentIntent(openApp(null, entryId.hashCode()))
            .addAction(0, context.getString(R.string.notice_undo), undo)
            .build()
        post(RECORDED_TAG, entryId.hashCode(), notification)
    }

    /**
     * "Entrou R$ 150,00 de Fulano. Toque para registrar" (RN-788). O toque
     * entrega [shareText] ao app como um texto compartilhado: abre a
     * conferência de sempre, que já sabe tratar Pix recebido e compra.
     */
    private fun ask(noticeId: String, shareText: String, title: String, text: String) {
        val share = Intent(context, MainActivity::class.java)
            .setAction(Intent.ACTION_SEND)
            .setType("text/plain")
            .putExtra(Intent.EXTRA_TEXT, shareText)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val tap = PendingIntent.getActivity(context, noticeId.hashCode(), share, FLAGS)
        val notification = base(AUTO_CHANNEL, title, text).setContentIntent(tap).build()
        post(ASK_TAG, noticeId.hashCode(), notification)
    }

    /** "3 gastos da semana ficaram para conferir. Confere em 1 minuto?" (RN-870). */
    fun review(count: Int) {
        val text = context.resources.getQuantityString(R.plurals.review_text, count, count)
        val notification = base(REVIEW_CHANNEL, context.getString(R.string.review_title), text)
            .setContentIntent(openApp(MainActivity.ACTION_REVIEW, REVIEW_ID))
            .build()
        post(REVIEW_TAG, REVIEW_ID, notification)
    }

    /** Tira o aviso do lançamento desfeito. */
    fun cancelRecorded(entryId: String) = manager.cancel(RECORDED_TAG, entryId.hashCode())

    /**
     * Na tela bloqueada, só "O Cajui lançou um gasto": o valor aparece
     * depois do desbloqueio (no espírito da RN-843).
     */
    private fun base(channel: String, title: String, text: String): NotificationCompat.Builder {
        ensureChannels()
        val hidden = NotificationCompat.Builder(context, channel)
            .setSmallIcon(R.drawable.ic_stat_cajui)
            .setContentTitle(context.getString(R.string.notice_locked_title))
            .build()
        return NotificationCompat.Builder(context, channel)
            .setSmallIcon(R.drawable.ic_stat_cajui)
            .setColor(context.getColor(R.color.cajui_accent))
            .setContentTitle(title)
            .setContentText(text)
            .setStyle(NotificationCompat.BigTextStyle().bigText(text))
            .setVisibility(NotificationCompat.VISIBILITY_PRIVATE)
            .setPublicVersion(hidden)
            .setAutoCancel(true)
    }

    private fun openApp(action: String?, requestCode: Int): PendingIntent {
        val open = Intent(context, MainActivity::class.java)
            .setAction(action ?: Intent.ACTION_MAIN)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(context, requestCode, open, FLAGS)
    }

    /** Sem a permissão de postar, o Android descarta; aqui só não se tenta. */
    private fun post(tag: String, id: Int, notification: android.app.Notification) {
        if (!manager.areNotificationsEnabled()) return
        try {
            manager.notify(tag, id, notification)
        } catch (denied: SecurityException) {
            return
        }
    }

    /**
     * Os dois canais nascem em prioridade baixa, sem som nem vibração: o
     * banco já tocou ao avisar a compra, e o resumo da semana não interrompe
     * ninguém (RN-825).
     */
    private fun ensureChannels() {
        // Canal só existe do Android 8 em diante; antes, a notificação vale
        // sem ele.
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val system = context.getSystemService(NotificationManager::class.java) ?: return
        system.createNotificationChannel(
            NotificationChannel(
                AUTO_CHANNEL,
                context.getString(R.string.channel_auto),
                NotificationManager.IMPORTANCE_LOW,
            ),
        )
        system.createNotificationChannel(
            NotificationChannel(
                REVIEW_CHANNEL,
                context.getString(R.string.channel_review),
                NotificationManager.IMPORTANCE_LOW,
            ),
        )
    }

    private companion object {
        const val AUTO_CHANNEL = "cajui.automatic"
        const val REVIEW_CHANNEL = "cajui.review"
        const val RECORDED_TAG = "cajui.recorded"
        const val ASK_TAG = "cajui.ask"
        const val REVIEW_TAG = "cajui.review"
        const val REVIEW_ID = 7401
        const val FLAGS = PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
    }
}
