package app.cajui.capture

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.MediaStore
import androidx.core.content.FileProvider
import java.io.File
import java.util.UUID

/**
 * Fotografar o comprovante dentro do Cajui (ADR-017).
 *
 * Cupom de supermercado é papel: não existe "compartilhar". Sem isto, o
 * caminho é sair do app, abrir a câmera, voltar e compartilhar — e a foto
 * ainda fica na galeria, com os valores da compra à vista de qualquer app que
 * leia fotos.
 *
 * A foto nasce **na área privada do app**, na mesma caixa de entrada do
 * compartilhamento: o resto do caminho é o mesmo já testado. Quem fotografa é
 * o app de câmera do aparelho, por intenção, então o Cajui **não pede
 * permissão de câmera** e não embute uma câmera própria.
 */
class PhotoIntake(private val activity: Activity) {

    private var target: File? = null

    /**
     * Abre a câmera do aparelho. Devolve `false` quando não há nenhuma — em
     * aparelho sem câmera, o botão simplesmente não deve existir.
     */
    fun start(): Boolean {
        val file = File(inbox(), UUID.randomUUID().toString())
        val intent = Intent(MediaStore.ACTION_IMAGE_CAPTURE)
            .putExtra(MediaStore.EXTRA_OUTPUT, uriOf(file))
            .addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        if (intent.resolveActivity(activity.packageManager) == null) return false
        target = file
        activity.startActivityForResult(intent, REQUEST)
        return true
    }

    /**
     * O item da foto tirada, no mesmo formato do compartilhamento; `null`
     * quando a pessoa desistiu ou a foto saiu vazia.
     */
    fun finish(requestCode: Int, resultCode: Int): Map<String, Any?>? {
        if (requestCode != REQUEST) return null
        val file = target ?: return null
        target = null
        if (resultCode != Activity.RESULT_OK || file.length() == 0L) {
            file.delete()
            return null
        }
        return mapOf(
            "id" to file.name,
            "kind" to "image",
            "path" to file.absolutePath,
            "fromCamera" to true,
        )
    }

    private fun uriOf(file: File): Uri = FileProvider.getUriForFile(
        activity,
        "${activity.packageName}.captures",
        file,
    )

    /** A mesma caixa de entrada do compartilhamento (ADR-006). */
    private fun inbox(): File =
        File(activity.filesDir, "capture-inbox").apply { mkdirs() }

    private companion object {
        const val REQUEST = 7201
    }
}
