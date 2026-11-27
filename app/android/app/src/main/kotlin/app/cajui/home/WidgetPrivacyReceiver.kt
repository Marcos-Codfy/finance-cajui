package app.cajui.home

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * O olho do widget grande: esconde ou mostra os valores de todos os
 * widgets do Cajui. A tela inicial fica à vista de quem estiver perto, e o
 * dinheiro da casa não precisa ficar (27/11/2026).
 */
class WidgetPrivacyReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val store = HomeSnapshotStore(context)
        store.hidden = !store.hidden
        HomeWidget.refresh(context)
    }
}
