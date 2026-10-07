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
 * do ML Kit, com o modelo embutido no APK. Quando pedido, sai junto a imagem
 * já reduzida que a IA vai ver (ADR-022): a foto, ou as primeiras páginas.
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

    /**
     * O texto de [path] e, com [withImages], as imagens para a IA. [onPage]
     * recebe o progresso real: página lida, total (RNF-PERF-06).
     *
     * Sem texto legível, mas com imagem, a leitura **não** falha: a foto
     * escura ou amassada que o celular não leu ainda pode ser lida pela IA.
     */
    fun read(
        path: String,
        kind: String,
        withImages: Boolean,
        onPage: (Int, Int) -> Unit,
    ): Map<String, Any> {
        val file = File(path)
        val images = mutableListOf<ByteArray>()
        val pages = if (kind == "pdf") {
            readPdf(file, if (withImages) images else null, onPage)
        } else {
            if (withImages) forAi { AiImage.fromFile(file) }?.let(images::add)
            listOf(orForAi(images) { readImage(file) })
        }
        val text = pages.joinToString("\n").trim()
        if (text.length < MIN_READABLE_CHARS && images.isEmpty()) {
            throw ReadFailure("E-CAPT-01")
        }
        return mapOf("text" to text, "pages" to pages.size, "images" to images)
    }

    private fun readImage(file: File): String =
        recognize(InputImage.fromFilePath(context, Uri.fromFile(file)))

    /** O texto de cada página; as primeiras [MAX_AI_PAGES] vão também para [images]. */
    private fun readPdf(
        file: File,
        images: MutableList<ByteArray>?,
        onPage: (Int, Int) -> Unit,
    ): List<String> {
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
                pdf.openPage(index).use { page ->
                    val bitmap = render(page)
                    if (images != null && index < MAX_AI_PAGES) {
                        forAi { AiImage.fromBitmap(bitmap) }?.let(images::add)
                    }
                    try {
                        orForAi(images.orEmpty()) { recognize(InputImage.fromBitmap(bitmap, 0)) }
                    } finally {
                        // Uma página desenhada tem dezenas de MB: não espera o coletor.
                        bitmap.recycle()
                    }
                }
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
        // Já é opaca: sem isto, a imagem da IA copiaria a página de novo só
        // para pôr fundo branco.
        bitmap.setHasAlpha(false)
        return bitmap
    }

    /**
     * A imagem para a IA é um extra: se ela não sai — decodificador recusou,
     * faltou memória —, a leitura segue só com o texto, em vez de falhar.
     */
    private fun forAi(make: () -> ByteArray): ByteArray? = try {
        make()
    } catch (failure: Throwable) {
        null
    }

    /**
     * O OCR do aparelho demorou demais (E-CAPT-07). Com a imagem na mão, a IA
     * ainda pode ler: o texto fica vazio, e a leitura segue. Sem ela, falha.
     */
    private fun orForAi(images: List<ByteArray>, read: () -> String): String = try {
        read()
    } catch (slow: ReadFailure) {
        if (slow.code != "E-CAPT-07" || images.isEmpty()) throw slow
        ""
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

        /** Quantas páginas de um PDF a IA vê: a de cima do extrato basta quase sempre. */
        const val MAX_AI_PAGES = 3

        /** Página que passa disso é interrompida (ADR-007, item 5). */
        const val PAGE_TIMEOUT_SECONDS = 10L
    }
}
