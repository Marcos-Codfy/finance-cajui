package app.cajui.reminders

import org.json.JSONObject

/**
 * Um lembrete de vencimento como o Dart o mandou (RN-1081): textos prontos,
 * a hora de chegar e a hora em que deixa de valer, em milissegundos no
 * relógio do aparelho. Aqui não há regra de dinheiro nenhuma.
 */
data class Reminder(
    val id: String,
    val eventKey: String,
    val fireAt: Long,
    val expiresAt: Long,
    val title: String,
    val text: String,
    val publicTitle: String,
    val publicText: String,
    val route: String,
    val oncePerEvent: Boolean,
) {

    /** O número da notificação: o mesmo nos dois momentos de um vencimento,
     *  para o aviso do dia tomar o lugar do de dois dias antes na bandeja. */
    val notificationId: Int get() = eventKey.hashCode()

    fun toJson(): JSONObject = JSONObject()
        .put("id", id)
        .put("eventKey", eventKey)
        .put("fireAt", fireAt)
        .put("expiresAt", expiresAt)
        .put("title", title)
        .put("text", text)
        .put("publicTitle", publicTitle)
        .put("publicText", publicText)
        .put("route", route)
        .put("oncePerEvent", oncePerEvent)

    companion object {

        /** O item do canal; nulo se falta algum campo — item ruim não entra. */
        fun fromMap(map: Map<*, *>): Reminder? {
            return Reminder(
                id = map["id"] as? String ?: return null,
                eventKey = map["eventKey"] as? String ?: return null,
                fireAt = (map["fireAt"] as? Number)?.toLong() ?: return null,
                expiresAt = (map["expiresAt"] as? Number)?.toLong() ?: return null,
                title = map["title"] as? String ?: return null,
                text = map["text"] as? String ?: return null,
                publicTitle = map["publicTitle"] as? String ?: return null,
                publicText = map["publicText"] as? String ?: return null,
                route = map["route"] as? String ?: return null,
                oncePerEvent = map["oncePerEvent"] as? Boolean ?: false,
            )
        }

        /** O que foi guardado por [toJson]; nulo se o registro não abre. */
        fun fromJson(json: JSONObject): Reminder? {
            val map = json.keys().asSequence().associateWith { json.get(it) }
            return fromMap(map)
        }
    }
}
