package app.cajui.capture

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.net.Uri
import android.os.ParcelFileDescriptor
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import java.io.File
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException

/** Uma leitura que não deu certo, com o código do catálogo de erros. */
class ReadFailure(val code: String) : Exception(code)

/**
 * Lê o texto de um comprovante **no aparelho** (ADR-007).
 *
 * Um caminho só para foto, captura de tela e PDF: o PDF vira imagem, página a
 * página, pelo `PdfRenderer` do próprio Android, e tudo passa pelo mesmo OCR
 * do ML Kit, com o modelo embutido no APK. Nenhuma imagem sai do aparelho, e
 * nenhum bitmap atravessa o canal para o Dart — só o texto.
 *
 * Roda fora da thread principal; quem chama cuida disso.
 */
class ReceiptOcr(private val context: Context) {

    /**
     * O leitor só nasce na primeira leitura. Criado junto com a atividade,
     * uma falha dele acontecia dentro de `configureFlutterEngine` e **fechava
     * o app ao abrir**; agora o pior que acontece é um comprovante que não
     * deu para ler, com o código do catálogo.
     */
    private val recognizer by lazy {
        TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
    }

    /** O texto de [path]. [onPage] recebe o progresso real: página lida, total (RNF-PERF-06). */
    fun read(path: String, kind: String, onPage: (Int, Int) -> Unit): Map<String, Any> {
        val file = File(path)
        val pages = if (kind == "pdf") readPdf(file, onPage) else listOf(readImage(file))
        val text = pages.joinToString("\n").trim()
        if (text.length < MIN_READABLE_CHARS) throw ReadFailure("E-CAPT-01")
        return mapOf("text" to text, "pages" to pages.size)
    }

    private fun readImage(file: File): String =
        recognize(InputImage.fromFilePath(context, Uri.fromFile(file)))

    private fun readPdf(file: File, onPage: (Int, Int) -> Unit): List<String> {
        val descriptor = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
        val renderer = try {
            PdfRenderer(descriptor)
        } catch (protected: SecurityException) {
            // PDF com senha: o Cajui não abre arquivo protegido.
            descriptor.close()
            throw ReadFailure("E-CAPT-04")
        }
        return renderer.use { pdf ->
            val total = minOf(pdf.pageCount, MAX_PAGES)
            (0 until total).map { index ->
                onPage(index + 1, total)
                pdf.openPage(index).use { page -> recognize(InputImage.fromBitmap(render(page), 0)) }
            }
        }
    }

    /** A página como imagem, com o lado maior em [RENDER_SIDE] px: letra de cupom precisa disso. */
    private fun render(page: PdfRenderer.Page): Bitmap {
        val scale = RENDER_SIDE.toFloat() / maxOf(page.width, page.height)
        val bitmap = Bitmap.createBitmap(
            (page.width * scale).toInt(),
            (page.height * scale).toInt(),
            Bitmap.Config.ARGB_8888,
        )
        // Fundo branco: PDF sem fundo próprio sairia transparente, e o OCR leria preto no preto.
        bitmap.eraseColor(Color.WHITE)
        page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
        return bitmap
    }

    private fun recognize(image: InputImage): String = try {
        Tasks.await(recognizer.process(image), PAGE_TIMEOUT_SECONDS, TimeUnit.SECONDS).text
    } catch (slow: TimeoutException) {
        throw ReadFailure("E-CAPT-07")
    }

    private companion object {
        /** Menos que isso não é comprovante lido: é ruído de imagem escura ou pequena. */
        const val MIN_READABLE_CHARS = 8

        /** Extrato comprido é conferido por partes; ler 40 páginas travaria a tela de leitura. */
        const val MAX_PAGES = 10

        const val RENDER_SIDE = 2000

        /** Página que passa disso é interrompida (ADR-007, item 5). */
        const val PAGE_TIMEOUT_SECONDS = 10L
    }
}
