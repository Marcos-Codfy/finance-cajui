package app.cajui.home

import android.content.Context
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import org.json.JSONArray
import org.json.JSONObject

/**
 * O retrato que o Dart publica para fora do app (ADR-025): o número do
 * widget, as próximas contas a vencer e os dias do que espera revisão.
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
            .putString(BILLS, encodeBills(snapshot["bills"]))
            .putString(VOUCHER_LABEL, snapshot["voucherLabel"] as? String)
            .putString(VOUCHER_AMOUNT, snapshot["voucherAmount"] as? String)
            .putLong(SAVED_AT, System.currentTimeMillis())
            .apply()
    }

    /**
     * As contas a vencer de hoje em diante, na ordem em que o app mandou.
     * A que venceu enquanto o app estava fechado sai: dizer "vence dia 10"
     * no dia 12 seria pior do que não dizer nada.
     */
    fun bills(today: Calendar = Calendar.getInstance()): List<WidgetBill> {
        val raw = preferences.getString(BILLS, null) ?: return emptyList()
        val array = runCatching { JSONArray(raw) }.getOrNull() ?: return emptyList()
        val first = iso(today)
        return (0 until array.length())
            .mapNotNull { array.optJSONObject(it) }
            .map { WidgetBill(it.optString("name"), it.optString("dueOn"), it.optString("day")) }
            .filter { it.name.isNotBlank() && it.dueOn >= first }
    }

    /** As contas em JSON: o SharedPreferences não guarda lista de mapas. */
    private fun encodeBills(raw: Any?): String {
        val array = JSONArray()
        (raw as? List<*>).orEmpty().filterIsInstance<Map<*, *>>().forEach { bill ->
            array.put(
                JSONObject()
                    .put("name", bill["name"] as? String ?: "")
                    .put("dueOn", bill["dueOn"] as? String ?: "")
                    .put("day", bill["day"] as? String ?: ""),
            )
        }
        return array.toString()
    }

    /** Se o app já publicou alguma vez. */
    val exists: Boolean get() = preferences.contains(AMOUNT)

    val label: String get() = preferences.getString(LABEL, null).orEmpty()
    val amount: String get() = preferences.getString(AMOUNT, null).orEmpty()
    val caption: String get() = preferences.getString(CAPTION, null).orEmpty()

    /** O rótulo do vale; `null` para quem não tem vale. */
    val voucherLabel: String? get() = preferences.getString(VOUCHER_LABEL, null)

    /** O valor do vale, já em texto; `null` para quem não tem vale. */
    val voucherAmount: String? get() = preferences.getString(VOUCHER_AMOUNT, null)

    /** Quando o app publicou o retrato pela última vez, em milissegundos; 0 se nunca. */
    val savedAt: Long get() = preferences.getLong(SAVED_AT, 0L)

    /**
     * Se os valores estão escondidos. É do aparelho, e não do retrato: o
     * `save` não mexe nisso, e esconder continua valendo depois de o app
     * publicar um número novo.
     */
    var hidden: Boolean
        get() = preferences.getBoolean(HIDDEN, false)
        set(value) = preferences.edit().putBoolean(HIDDEN, value).apply()

    /**
     * Se o número ainda é deste mês. No dia 1, o do mês passado não vale
     * mais, e mostrá-lo seria dizer uma sobra que já não existe.
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
        const val BILLS = "bills"
        const val VOUCHER_LABEL = "voucherLabel"
        const val VOUCHER_AMOUNT = "voucherAmount"
        const val SAVED_AT = "savedAt"
        const val HIDDEN = "hidden"

        /** A mesma janela de `weekly_review.dart`. */
        const val WINDOW_DAYS = 7
    }
}
