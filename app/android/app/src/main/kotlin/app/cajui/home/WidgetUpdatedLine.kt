package app.cajui.home

import android.content.Context
import app.cajui.R
import java.util.Calendar
import java.util.Locale

/**
 * "Atualizado às 14h32", "Atualizado ontem às 14h32" ou "Atualizado em 17
 * de nov.": de quando é o número do widget. O widget só muda quando o app
 * publica, e um número de dois dias atrás, sem data, parece de agora.
 *
 * A frase é montada aqui, na hora de desenhar, porque "ontem" depende do
 * dia em que o widget é olhado, e não do dia em que o app publicou.
 */
object WidgetUpdatedLine {

    private val shortMonths = listOf(
        "jan.", "fev.", "mar.", "abr.", "maio", "jun.",
        "jul.", "ago.", "set.", "out.", "nov.", "dez.",
    )

    /** A frase para [savedAt]; vazia se o app nunca publicou. */
    fun of(context: Context, savedAt: Long, now: Calendar = Calendar.getInstance()): String {
        if (savedAt <= 0L) return ""
        val at = Calendar.getInstance().apply { timeInMillis = savedAt }
        return when (daysBetween(at, now)) {
            0 -> context.getString(R.string.home_widget_updated_today, time(at))
            1 -> context.getString(R.string.home_widget_updated_yesterday, time(at))
            else -> context.getString(R.string.home_widget_updated_on, day(at))
        }
    }

    /** "14h32", como o app escreve a hora. */
    private fun time(at: Calendar): String =
        String.format(Locale.US, "%dh%02d", at.get(Calendar.HOUR_OF_DAY), at.get(Calendar.MINUTE))

    private fun day(at: Calendar): String =
        "${at.get(Calendar.DAY_OF_MONTH)} de ${shortMonths[at.get(Calendar.MONTH)]}"

    /** Dias de calendário entre os dois instantes, contando pela meia-noite. */
    private fun daysBetween(from: Calendar, to: Calendar): Int {
        fun midnight(day: Calendar) = (day.clone() as Calendar).apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        return ((midnight(to) - midnight(from)) / DAY_MILLIS).toInt()
    }

    private const val DAY_MILLIS = 24L * 60 * 60 * 1000
}
