package app.cajui.home

import android.content.Context
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/**
 * O retrato que o Dart publica para fora do app (ADR-025): o número do
 * widget e os dias do que espera revisão.
 *
 * Chega pronto, em texto. Aqui não há regra de dinheiro nenhuma: só guardar,
 * comparar datas e contar dias.
 */
class HomeSnapshotStore(context: Context) {

    private val preferences = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    /** Guarda o retrato que veio do canal. */
    fun save(snapshot: Map<*, *>) {
        val dates = (snapshot["reviewDates"] as? List<*>).orEmpty().filterIsInstance<String>()
        preferences.edit()
            .putString(LABEL, snapshot["label"] as? String)
            .putString(AMOUNT, snapshot["amount"] as? String)
            .putString(CAPTION, snapshot["caption"] as? String)
            .putString(VALID_UNTIL, snapshot["validUntil"] as? String)
            .putString(REVIEW_DATES, dates.joinToString(","))
            .apply()
    }

    /** Se o app já publicou alguma vez. */
    val exists: Boolean get() = preferences.contains(AMOUNT)

    val label: String get() = preferences.getString(LABEL, null).orEmpty()
    val amount: String get() = preferences.getString(AMOUNT, null).orEmpty()
    val caption: String get() = preferences.getString(CAPTION, null).orEmpty()

    /**
     * Se o número ainda é desta semana. Na segunda, o da semana passada não
     * vale mais, e mostrá-lo seria dizer um limite que já não existe.
     * Datas em ISO comparam como texto.
     */
    fun isCurrent(today: Calendar = Calendar.getInstance()): Boolean {
        val until = preferences.getString(VALID_UNTIL, null) ?: return false
        return iso(today) <= until
    }

    /** Quantos lançamentos dos últimos sete dias, contando hoje, esperam revisão. */
    fun reviewCount(today: Calendar = Calendar.getInstance()): Int {
        val raw = preferences.getString(REVIEW_DATES, null).orEmpty()
        val from = (today.clone() as Calendar).apply { add(Calendar.DAY_OF_YEAR, -(WINDOW_DAYS - 1)) }
        val first = iso(from)
        val last = iso(today)
        return raw.split(",").count { it.isNotBlank() && it >= first && it <= last }
    }

    private fun iso(day: Calendar): String =
        SimpleDateFormat("yyyy-MM-dd", Locale.US).format(day.time)

    private companion object {
        const val FILE = "cajui.home"
        const val LABEL = "label"
        const val AMOUNT = "amount"
        const val CAPTION = "caption"
        const val VALID_UNTIL = "validUntil"
        const val REVIEW_DATES = "reviewDates"

        /** A mesma janela de `weekly_review.dart`. */
        const val WINDOW_DAYS = 7
    }
}
