package app.cajui.home

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import app.cajui.MainActivity
import app.cajui.R

/**
 * O desenho dos dois tamanhos do widget, a partir do último retrato que o
 * app publicou: o pequeno (2×1) só com o número do mês, e o grande (4×2)
 * com o número, as próximas contas a vencer e os três atalhos.
 *
 * Aqui não há conta: o número, as frases e a lista chegam prontos do Dart.
 * Passado o mês a que o número se refere, os dois pedem para abrir o app,
 * que publica o novo.
 */
object HomeWidgetViews {

    /** As linhas de conta do layout grande, na ordem: cabem três. */
    private val billRows = listOf(
        Triple(R.id.home_bill_1, R.id.home_bill_1_name, R.id.home_bill_1_day),
        Triple(R.id.home_bill_2, R.id.home_bill_2_name, R.id.home_bill_2_day),
        Triple(R.id.home_bill_3, R.id.home_bill_3_name, R.id.home_bill_3_day),
    )

    /** O grande: número, contas a vencer, câmera, galeria e "+". */
    fun large(context: Context): RemoteViews {
        val store = HomeSnapshotStore(context)
        val views = RemoteViews(context.packageName, R.layout.home_widget)
        val current = number(context, store, views)
        views.setTextViewText(
            R.id.home_caption,
            if (current) store.caption else context.getString(R.string.home_widget_stale_caption),
        )
        bills(views, if (current) store.bills() else emptyList(), current)
        arrival(context, views)
        views.setOnClickPendingIntent(R.id.home_camera, open(context, MainActivity.ACTION_PHOTO, 1))
        views.setOnClickPendingIntent(R.id.home_gallery, open(context, MainActivity.ACTION_PICK, 2))
        views.setOnClickPendingIntent(R.id.home_new_entry, open(context, MainActivity.ACTION_NEW_ENTRY, 3))
        return views
    }

    /** O pequeno: só o rótulo e o número; o toque abre o app. */
    fun small(context: Context): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.home_widget_small)
        number(context, HomeSnapshotStore(context), views)
        arrival(context, views)
        return views
    }

    /**
     * Escreve o rótulo e o número, ou o "mês novo" quando o retrato é de
     * outro mês. Devolve se o retrato vale.
     */
    private fun number(context: Context, store: HomeSnapshotStore, views: RemoteViews): Boolean {
        val current = store.exists && store.isCurrent()
        views.setTextViewText(
            R.id.home_label,
            if (current) store.label else context.getString(R.string.home_widget_stale_label),
        )
        views.setTextViewText(
            R.id.home_amount,
            if (current) store.amount else context.getString(R.string.home_widget_stale_amount),
        )
        return current
    }

    /**
     * As linhas de conta: uma por conta, até três. Sem nenhuma, a frase de
     * que não há conta a vencer; com o retrato vencido, nem isso — a frase
     * de baixo já pede para abrir o app.
     */
    private fun bills(views: RemoteViews, bills: List<WidgetBill>, current: Boolean) {
        billRows.forEachIndexed { index, (row, name, day) ->
            val bill = bills.getOrNull(index)
            views.setViewVisibility(row, if (bill == null) View.GONE else View.VISIBLE)
            if (bill != null) {
                views.setTextViewText(name, bill.name)
                views.setTextViewText(day, bill.day)
            }
        }
        val empty = current && bills.isEmpty()
        views.setViewVisibility(R.id.home_bills_empty, if (empty) View.VISIBLE else View.GONE)
    }

    /**
     * Tocar no número, ou em qualquer parte do vidro, abre o app com a
     * chegada pelo widget: o Android 12+ faz o app crescer de dentro dele.
     */
    private fun arrival(context: Context, views: RemoteViews) {
        val arrival = open(context, MainActivity.ACTION_WIDGET, 0)
        views.setOnClickPendingIntent(android.R.id.background, arrival)
        views.setOnClickPendingIntent(R.id.home_balance, arrival)
    }

    /**
     * Abre o app já na câmera, já na galeria, já no novo lançamento, ou
     * no Início, chegando pelo widget.
     */
    private fun open(context: Context, action: String, requestCode: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java)
            .setAction(action)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
    }
}
