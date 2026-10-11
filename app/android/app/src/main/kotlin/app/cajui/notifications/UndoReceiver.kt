package app.cajui.notifications

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * O botão "Desfazer" do aviso de lançamento automático (RN-786).
 *
 * Não cancela nada aqui: o pedido entra na mesma fila das notificações, e o
 * Dart o trata na ordem — nunca antes do lançamento que ele desfaz. O aviso
 * sai na hora, para a pessoa ver que o toque pegou.
 */
class UndoReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION) return
        val entryId = intent.getStringExtra(EXTRA_ENTRY) ?: return
        NoticePoster(context).cancelRecorded(entryId)
        NoticeQueue(context).undo(entryId)
        NoticeRouter.kick(context)
    }

    companion object {
        const val ACTION = "app.cajui.action.UNDO"
        const val EXTRA_ENTRY = "entryId"
    }
}
