package app.cajui.reminders

import android.content.Context
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

/**
 * Os lembretes marcados e o que já foi mostrado, na área privada do app
 * (RN-1081, RN-1086).
 *
 * A lista é trocada inteira a cada publicação do Dart. O que já foi
 * mostrado fica à parte e sobrevive à troca: é o que impede o mesmo
 * lembrete de chegar duas vezes, e, no mês com falta, o segundo aviso do
 * mesmo vencimento. Cada marca some sozinha depois do vencimento.
 */
class ReminderStore(context: Context) {

    private val preferences = context.getSharedPreferences(FILE, Context.MODE_PRIVATE)

    /** Troca a lista inteira por [reminders]. */
    fun replace(reminders: List<Reminder>) {
        val array = JSONArray()
        reminders.forEach { array.put(it.toJson()) }
        preferences.edit().putString(ITEMS, array.toString()).apply()
    }

    /** A lista em vigor. Registro que não abre vale como lista vazia. */
    fun items(): List<Reminder> {
        val array = try {
            JSONArray(preferences.getString(ITEMS, null) ?: "[]")
        } catch (broken: JSONException) {
            JSONArray()
        }
        return (0 until array.length()).mapNotNull { index ->
            array.optJSONObject(index)?.let(Reminder::fromJson)
        }
    }

    /** Se [reminder] já passou pela bandeja — ou foi calado. */
    fun wasDelivered(reminder: Reminder): Boolean = marks(DELIVERED).has(reminder.id)

    /** Se algum aviso do vencimento de [reminder] já foi mostrado. */
    fun eventShown(reminder: Reminder): Boolean = marks(SHOWN).has(reminder.eventKey)

    /** Anota que [reminder] foi tratado; [shown] se ele chegou a aparecer. */
    fun markDelivered(reminder: Reminder, shown: Boolean) {
        val delivered = marks(DELIVERED).put(reminder.id, reminder.expiresAt)
        val events = marks(SHOWN)
        if (shown) events.put(reminder.eventKey, reminder.expiresAt)
        preferences.edit()
            .putString(DELIVERED, delivered.toString())
            .putString(SHOWN, events.toString())
            .apply()
    }

    /** Esquece as marcas dos vencimentos que já passaram de [now]. */
    fun forgetExpired(now: Long) {
        val delivered = withoutExpired(marks(DELIVERED), now)
        val events = withoutExpired(marks(SHOWN), now)
        preferences.edit()
            .putString(DELIVERED, delivered.toString())
            .putString(SHOWN, events.toString())
            .apply()
    }

    private fun marks(key: String): JSONObject = try {
        JSONObject(preferences.getString(key, null) ?: "{}")
    } catch (broken: JSONException) {
        JSONObject()
    }

    private fun withoutExpired(marks: JSONObject, now: Long): JSONObject {
        val kept = JSONObject()
        marks.keys().forEach { key ->
            val expiresAt = marks.optLong(key)
            if (expiresAt > now) kept.put(key, expiresAt)
        }
        return kept
    }

    private companion object {
        const val FILE = "cajui.reminders"
        const val ITEMS = "items"
        const val DELIVERED = "delivered"
        const val SHOWN = "shown"
    }
}
