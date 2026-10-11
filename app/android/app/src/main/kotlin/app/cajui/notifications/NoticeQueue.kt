package app.cajui.notifications

import android.content.Context
import org.json.JSONObject
import java.io.File

/**
 * A fila das notificações do banco, na área privada do app (ADR-025).
 *
 * Arquivo, e não memória: o leitor de notificações recebe o aviso com o app
 * fechado, e o Dart que o trata pode subir segundos depois — ou morrer no
 * meio. Um item só sai daqui quando o Dart diz que tratou (`remove`); se o
 * processo cair antes, ele é tratado na próxima vez, e a chave derivada da
 * notificação garante que não lança duas vezes.
 *
 * O texto fica em claro, mas só enquanto espera: são segundos, na pasta que
 * nenhum outro app alcança. Depois de tratado, o que sobra é o lançamento,
 * no registro cifrado.
 */
class NoticeQueue(context: Context) {

    private val folder = File(context.filesDir, "bank-notices").apply { mkdirs() }
    private val queue = File(folder, "queue.jsonl")
    private val seen = File(folder, "seen.txt")

    /**
     * Põe [item] no fim da fila. Devolve `false` quando a mesma notificação
     * já passou por aqui: o Android repete o aviso quando o app do banco o
     * atualiza, e cada repetição seria um lançamento a mais.
     */
    fun offer(item: JSONObject): Boolean = synchronized(LOCK) {
        val id = item.optString("id")
        val known = seenIds()
        if (id.isEmpty() || id in known) return false
        queue.appendText(item.toString() + "\n")
        seen.writeText((known.takeLast(MAX_SEEN - 1) + id).joinToString("\n"))
        true
    }

    /** O "Desfazer" entra na mesma fila: depois do lançamento que desfaz. */
    fun undo(entryId: String) = synchronized(LOCK) {
        val item = JSONObject()
            .put("id", "undo-$entryId")
            .put("type", "undo")
            .put("entryId", entryId)
        queue.appendText(item.toString() + "\n")
    }

    /** Tudo o que espera, na ordem em que chegou. */
    fun all(): List<Map<String, Any?>> = synchronized(LOCK) {
        lines().mapNotNull { parse(it)?.let(::asMap) }
    }

    /** Se há algo esperando. */
    fun hasItems(): Boolean = synchronized(LOCK) { lines().isNotEmpty() }

    /**
     * Tira da fila os itens [ids]. Linha que não abre — escrita pela metade
     * quando o processo morreu — sai junto: ficaria lá para sempre.
     */
    fun remove(ids: Set<String>) = synchronized(LOCK) {
        val kept = lines().filter { line ->
            val item = parse(line)
            item != null && item.optString("id") !in ids
        }
        queue.writeText(kept.joinToString("") { it + "\n" })
    }

    private fun lines(): List<String> =
        if (queue.exists()) queue.readLines().filter { it.isNotBlank() } else emptyList()

    private fun seenIds(): List<String> =
        if (seen.exists()) seen.readLines().filter { it.isNotBlank() } else emptyList()

    private fun parse(line: String): JSONObject? = try {
        JSONObject(line)
    } catch (broken: Exception) {
        null
    }

    private fun asMap(item: JSONObject): Map<String, Any?> =
        item.keys().asSequence().associateWith { key -> item.opt(key) }

    private companion object {
        val LOCK = Any()

        /** Quantas notificações já vistas são lembradas para não repetir. */
        const val MAX_SEEN = 300
    }
}
