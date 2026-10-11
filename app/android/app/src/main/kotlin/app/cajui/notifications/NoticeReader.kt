package app.cajui.notifications

import android.app.Notification
import android.service.notification.StatusBarNotification
import org.json.JSONObject
import java.security.MessageDigest

/**
 * Tira de uma notificação do Android só o que o Dart precisa: de onde veio,
 * o título, o texto e quando chegou. Ícone, imagem, botões e o resto ficam.
 */
object NoticeReader {

    /** O mesmo teto do lado do Dart: notificação não é livro. */
    private const val MAX_TEXT = 2000

    /**
     * O item da fila para [sbn]; `null` para o que não é aviso de verdade —
     * o resumo de um grupo repete o que os avisos dele já disseram, e o aviso
     * fixo é de progresso, não de movimentação.
     */
    fun read(sbn: StatusBarNotification): JSONObject? {
        val notification = sbn.notification ?: return null
        if (notification.flags and Notification.FLAG_GROUP_SUMMARY != 0) return null
        if (sbn.isOngoing) return null
        val extras = notification.extras ?: return null
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
        // O texto expandido, quando há: o recolhido costuma cortar o nome
        // do lugar no meio.
        val text = (extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
            ?: extras.getCharSequence(Notification.EXTRA_TEXT))?.toString().orEmpty()
        if (title.isBlank() && text.isBlank()) return null
        return JSONObject()
            .put("id", idOf(sbn, title, text))
            .put("type", "bank")
            .put("package", sbn.packageName)
            .put("title", title.take(MAX_TEXT))
            .put("text", text.take(MAX_TEXT))
            .put("postedAt", sbn.postTime)
    }

    /**
     * A chave da notificação: a mesma a cada vez que o Android repete o
     * aviso, outra para a compra seguinte — mesmo que seja do mesmo valor,
     * no mesmo lugar, porque a hora que o banco carimbou é outra.
     */
    private fun idOf(sbn: StatusBarNotification, title: String, text: String): String {
        val source = listOf(sbn.packageName, sbn.key, sbn.notification.`when`, title, text)
            .joinToString("|")
        val digest = MessageDigest.getInstance("SHA-256").digest(source.toByteArray())
        return digest.take(12).joinToString("") { "%02x".format(it) }
    }
}
