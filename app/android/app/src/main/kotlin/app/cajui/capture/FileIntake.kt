package app.cajui.capture

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri

/**
 * Escolher do próprio aparelho uma foto, um print ou um PDF — o extrato que
 * o banco baixou, o print do Pix que está na galeria.
 *
 * Sem isto, o único caminho era sair do Cajui, abrir a galeria e
 * compartilhar. Quem mostra os arquivos é o seletor do próprio Android, por
 * intenção: o Cajui **não pede permissão de ler a galeria** e só enxerga o
 * que a pessoa tocou.
 *
 * O que for escolhido entra na mesma caixa de entrada do compartilhamento:
 * o resto do caminho — conferir tipo e tamanho, ler, propor — é o mesmo.
 */
class FileIntake(private val activity: Activity) {

    /**
     * Abre o seletor, com várias escolhas de uma vez. Devolve `false` quando
     * o aparelho não tem seletor nenhum — aí o botão não serve.
     */
    fun start(): Boolean {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType("*/*")
            .putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("image/*", "application/pdf"))
            .putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
        return try {
            activity.startActivityForResult(intent, REQUEST)
            true
        } catch (none: ActivityNotFoundException) {
            false
        }
    }

    /**
     * O que foi escolhido, na ordem; vazio quando a pessoa desistiu, e
     * `null` quando o resultado não é deste seletor.
     */
    fun finish(requestCode: Int, resultCode: Int, data: Intent?): List<Uri>? {
        if (requestCode != REQUEST) return null
        if (resultCode != Activity.RESULT_OK || data == null) return emptyList()
        val clip = data.clipData
        if (clip != null) return (0 until clip.itemCount).map { clip.getItemAt(it).uri }
        return listOfNotNull(data.data)
    }

    private companion object {
        const val REQUEST = 7202
    }
}
