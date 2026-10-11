package app.cajui.files

import android.app.Activity
import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Entrega um arquivo pronto pela tela de compartilhar do Android: a planilha
 * do mês (RN-1090) sai para Arquivos, WhatsApp, Excel ou Planilhas, à escolha
 * de quem exporta.
 *
 * O arquivo vai para a pasta temporária do app, numa subpasta só dele, e a
 * permissão de leitura vale só para o arquivo mandado. A exportação anterior
 * é apagada antes: a pasta nunca acumula meses que já saíram.
 */
class FileShareChannel(private val activity: Activity, messenger: BinaryMessenger) {

    init {
        MethodChannel(messenger, NAME).setMethodCallHandler(::handle)
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "share") return result.notImplemented()
        val name = call.argument<String>("name")
        val mimeType = call.argument<String>("mimeType")
        val bytes = call.argument<ByteArray>("bytes")
        if (name == null || mimeType == null || bytes == null) {
            return result.error("args", "nome, tipo e conteúdo são obrigatórios", null)
        }
        share(save(name, bytes), mimeType)
        result.success(null)
    }

    private fun save(name: String, bytes: ByteArray): File {
        val folder = File(activity.cacheDir, FOLDER).apply { mkdirs() }
        folder.listFiles()?.forEach { it.delete() }
        // O nome vem do app, mas o arquivo nunca sai da pasta: só o último
        // pedaço do caminho vale.
        return File(folder, File(name).name).apply { writeBytes(bytes) }
    }

    private fun share(file: File, mimeType: String) {
        val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.captures", file)
        val send = Intent(Intent.ACTION_SEND)
            .setType(mimeType)
            .putExtra(Intent.EXTRA_STREAM, uri)
            .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        activity.startActivity(Intent.createChooser(send, file.name))
    }

    companion object {
        /** O canal, o mesmo de `native_file_hand_off.dart`. */
        const val NAME = "cajui/files"

        private const val FOLDER = "exports"
    }
}
