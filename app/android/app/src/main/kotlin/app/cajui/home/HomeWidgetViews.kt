package app.cajui.home

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import app.cajui.MainActivity
import app.cajui.R

/**
 * O desenho dos widgets, a partir do último retrato que o app publicou: o
 * pequeno (2×1) só com o número do mês, o do vale (2×1) com o vale
 * alimentação, e o grande (4×2) com o número, de quando ele é, as próximas
 * contas a vencer, os três atalhos e o olho que esconde os valores.
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
        views.setTextViewText(R.id.home_caption, caption(context, store, current))
        bills(views, if (current) store.bills() else emptyList(), current)
        arrival(context, views)
        privacy(context, store, views)
        views.setOnClickPendingIntent(R.id.home_camera, open(context, MainActivity.ACTION_PHOTO, 1))
        views.setOnClickPendingIntent(R.id.home_gallery, open(context, MainActivity.ACTION_PICK, 2))
        views.setOnClickPendingIntent(R.id.home_new_entry, open(context, MainActivity.ACTION_NEW_ENTRY, 3))
        return views
    }

    /**
     * O do vale: o saldo do vale alimentação, ou o do mês. Nunca somado ao
     * número do mês (RN-111). Sem vale, diz isso, em vez de "R$ 0,00".
     */
    fun voucher(context: Context): RemoteViews {
        val store = HomeSnapshotStore(context)
        val views = RemoteViews(context.packageName, R.layout.home_widget_voucher)
        val current = store.exists && store.isCurrent()
        val label = store.voucherLabel
        val amount = store.voucherAmount
        val (shownLabel, shownAmount) = when {
            !current -> context.getString(R.string.home_widget_stale_label) to
                context.getString(R.string.home_widget_stale_amount)
            label == null || amount == null -> context.getString(R.string.home_widget_voucher_none_label) to
                context.getString(R.string.home_widget_voucher_none_amount)
            else -> label to masked(context, store, amount)
        }
        views.setTextViewText(R.id.home_label, shownLabel)
        views.setTextViewText(R.id.home_amount, shownAmount)
        arrival(context, views)
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
            if (current) masked(context, store, store.amount) else context.getString(R.string.home_widget_stale_amount),
        )
        return current
    }

    /** O valor, ou os pontinhos quando a pessoa escondeu os valores. */
    private fun masked(context: Context, store: HomeSnapshotStore, amount: String): String =
        if (store.hidden) context.getString(R.string.home_widget_hidden_amount) else amount

    /**
     * A frase de baixo do grande, com de quando é o número na frente: a
     * frase corta no fim quando falta lugar, e a data é o que não pode
     * sumir.
     */
    private fun caption(context: Context, store: HomeSnapshotStore, current: Boolean): String {
        if (!current) return context.getString(R.string.home_widget_stale_caption)
        val updated = WidgetUpdatedLine.of(context, store.savedAt)
        return if (updated.isEmpty()) store.caption else "$updated · ${store.caption}"
    }

    /** O olho: o desenho diz o estado, e o toque troca. */
    private fun privacy(context: Context, store: HomeSnapshotStore, views: RemoteViews) {
        val hidden = store.hidden
        views.setImageViewResource(
            R.id.home_privacy,
            if (hidden) R.drawable.ic_widget_eye_off else R.drawable.ic_widget_eye,
        )
        views.setContentDescription(
            R.id.home_privacy,
            context.getString(if (hidden) R.string.home_widget_show else R.string.home_widget_hide),
        )
        val toggle = PendingIntent.getBroadcast(
            context,
            PRIVACY_REQUEST,
            Intent(context, WidgetPrivacyReceiver::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        views.setOnClickPendingIntent(R.id.home_privacy, toggle)
    }

    /** Diferente dos pedidos de abrir o app (0 a 3). */
    private const val PRIVACY_REQUEST = 20

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
