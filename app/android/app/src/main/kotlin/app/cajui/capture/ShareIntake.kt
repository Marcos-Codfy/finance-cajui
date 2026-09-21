package app.cajui.capture

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.StatFs
import android.provider.OpenableColumns
import java.io.File
import java.util.UUID

/**
 * Recebe o que outro app compartilhou e o traz para dentro do Cajui.
 *
 * Tudo o que chega aqui é entrada não confiável (ADR-006): o nome do arquivo é
 * descartado, o tipo declarado não vale nada até os primeiros bytes
 * confirmarem, e o tamanho é conferido antes de um único byte ser copiado.
 * Só depois de copiado para a área privada do app é que o Dart fica sabendo —
 * daí em diante a permissão temporária do app de origem deixa de importar.
 */
class ShareIntake(private val context: Context) {

    /** Os itens de [intent], na ordem recebida (RN-705). Vazio se não é compartilhamento. */
    fun receive(intent: Intent?): List<Map<String, Any?>> {
        if (intent == null) return emptyList()
        return when (intent.action) {
            Intent.ACTION_SEND -> listOf(receiveOne(intent, streamOf(intent)))
            Intent.ACTION_SEND_MULTIPLE -> streamsOf(intent).map { receiveOne(intent, it) }
            else -> emptyList()
        }
    }

    private fun receiveOne(intent: Intent, stream: Uri?): Map<String, Any?> {
        val id = UUID.randomUUID().toString()
        if (stream == null) return receiveText(id, intent.getStringExtra(Intent.EXTRA_TEXT))
        return try {
            receiveFile(id, stream)
        } catch (denied: SecurityException) {
            // O app de origem não liberou a leitura do arquivo.
            failure(id, "E-CAPT-05")
        }
    }

    private fun receiveText(id: String, text: String?): Map<String, Any?> {
        if (text.isNullOrBlank()) return failure(id, "E-CAPT-02")
        return mapOf("id" to id, "kind" to "text", "text" to text.take(MAX_TEXT_CHARS))
    }

    private fun receiveFile(id: String, stream: Uri): Map<String, Any?> {
        val size = sizeOf(stream)
        if (size > MAX_BYTES) return failure(id, "E-CAPT-03", mapOf("sizeBytes" to size))
        val missing = size + SPARE_BYTES - freeBytes()
        if (missing > 0) return failure(id, "E-CAPT-06", mapOf("missingBytes" to missing))

        val target = File(inbox(), id)
        context.contentResolver.openInputStream(stream)?.use { input ->
            target.outputStream().use { output -> input.copyTo(output) }
        } ?: return failure(id, "E-CAPT-05")

        val kind = kindOf(target)
        if (kind == null || target.length() > MAX_BYTES) {
            target.delete()
            return failure(id, if (kind == null) "E-CAPT-02" else "E-CAPT-03")
        }
        return mapOf("id" to id, "kind" to kind, "path" to target.absolutePath)
    }

    /** Apaga o arquivo local de uma captura descartada (RN-723). Só dentro da caixa de entrada. */
    fun discard(path: String): Boolean {
        val file = File(path).canonicalFile
        if (file.parentFile != inbox().canonicalFile) return false
        return file.delete()
    }

    private fun inbox(): File = File(context.filesDir, "capture-inbox").apply { mkdirs() }

    private fun freeBytes(): Long = StatFs(context.filesDir.path).availableBytes

    /** O tamanho declarado pelo provedor. Se ele não disser, a cópia confere de novo. */
    private fun sizeOf(stream: Uri): Long {
        val columns = arrayOf(OpenableColumns.SIZE)
        context.contentResolver.query(stream, columns, null, null, null)?.use { cursor ->
            if (cursor.moveToFirst() && !cursor.isNull(0)) return cursor.getLong(0)
        }
        return 0
    }

    /** O tipo pelos primeiros bytes. O tipo declarado pelo app de origem não é consultado. */
    private fun kindOf(file: File): String? {
        val head = ByteArray(12)
        val read = file.inputStream().use { it.read(head) }
        if (read < 4) return null
        return when {
            head.startsWith(0xFF, 0xD8, 0xFF) -> "image"
            head.startsWith(0x89, 0x50, 0x4E, 0x47) -> "image"
            read >= 12 && head.hasAscii(0, "RIFF") && head.hasAscii(8, "WEBP") -> "image"
            head.hasAscii(0, "%PDF") -> "pdf"
            else -> null
        }
    }

    private fun failure(id: String, code: String, detail: Map<String, Any?> = emptyMap()) =
        mapOf("id" to id, "error" to code, "detail" to detail)

    @Suppress("DEPRECATION")
    private fun streamOf(intent: Intent): Uri? = intent.getParcelableExtra(Intent.EXTRA_STREAM)

    @Suppress("DEPRECATION")
    private fun streamsOf(intent: Intent): List<Uri?> =
        intent.getParcelableArrayListExtra<Uri>(Intent.EXTRA_STREAM).orEmpty().take(MAX_ITEMS)

    private fun ByteArray.startsWith(vararg bytes: Int): Boolean =
        bytes.withIndex().all { (index, byte) -> this[index] == byte.toByte() }

    private fun ByteArray.hasAscii(offset: Int, text: String): Boolean =
        text.withIndex().all { (index, char) -> this[offset + index] == char.code.toByte() }

    private companion object {
        /** 15 MB: um print ou um PDF de comprovante cabem com folga (RN-703). */
        const val MAX_BYTES = 15L * 1024 * 1024

        /** Folga de disco além do arquivo, para o registro continuar gravando. */
        const val SPARE_BYTES = 4L * 1024 * 1024

        /** O mesmo teto que o domínio aplica ao texto lido. */
        const val MAX_TEXT_CHARS = 8000

        /** Compartilhamento em lote é conferido um por vez; mais que isso é engano. */
        const val MAX_ITEMS = 10
    }
}
