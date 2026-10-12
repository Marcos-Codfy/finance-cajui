package app.cajui.capture

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.net.Uri
import android.os.ParcelFileDescriptor
import com.google.android.gms.tasks.Tasks
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.Text
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import java.io.File
import java.util.concurrent.TimeUnit
import java.util.concurrent.TimeoutException

/** Uma leitura que não deu certo, com o código do catálogo de erros. */
class ReadFailure(val code: String) : Exception(code)

/** Uma página lida: o texto do ML Kit e o mesmo texto em linhas, pela posição ([TextRows]). */
class PageRead(val text: String, val rows: String) {
    companion object {
        /** A página que o OCR não leu a tempo, mas cuja imagem a IA ainda vê. */
        val EMPTY = PageRead("", "")

        fun of(result: Text) = PageRead(result.text, TextRows.of(result))
    }
}

/**
 * Lê o texto de um comprovante **no aparelho** (ADR-007).
 *
 * Um caminho só para foto, captura de tela e PDF: o PDF vira imagem, página a
 * página, pelo `PdfRenderer` do próprio Android, e tudo passa pelo mesmo OCR
 * do ML Kit, com o modelo embutido no APK. Quando pedido, sai junto a imagem
 * já reduzida que a IA vai ver (ADR-022): a foto, ou as primeiras páginas.
 *
 * Sai também o texto de cada página, separado, e quantas páginas o PDF tem
 * de verdade: o extrato é lido uma página por vez, e o que ficou de fora é
 * dito — "Li as páginas 1 a 20 de 24" (RN-1101, ADR-030).
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
     *
     * Volta o texto juntado, que o comprovante lê, e também o de cada
     * página (`pageTexts`), o mesmo em linhas pela posição (`pageRows`), que
     * o extrato lê, o total real de páginas (`pageCount`) e a página de cada
     * imagem (`imagePages`, a partir de 1): imagem que não saiu não desloca
     * as outras.
     */
    fun read(
        path: String,
        kind: String,
        withImages: Boolean,
        onPage: (Int, Int) -> Unit,
    ): Map<String, Any> {
        val file = File(path)
        val images = AiPages(withImages)
        val (pages, pageCount) = if (kind == "pdf") {
            readPdf(file, images, onPage)
        } else {
            images.add(1) { AiImage.fromFile(file) }
            listOf(orForAi(images.bytes) { readImage(file) }) to 1
        }
        val text = pages.joinToString("\n") { it.text }.trim()
        if (text.length < MIN_READABLE_CHARS && images.bytes.isEmpty()) {
            throw ReadFailure("E-CAPT-01")
        }
        return mapOf(
            "text" to text,
            "pages" to pages.size,
            "pageTexts" to pages.map { it.text },
            "pageRows" to pages.map { it.rows },
            "pageCount" to pageCount,
            "images" to images.bytes,
            "imagePages" to images.pages,
        )
    }

    private fun readImage(file: File): PageRead =
        recognize(InputImage.fromFilePath(context, Uri.fromFile(file)))

    /**
     * O texto de cada página lida e o total de páginas do arquivo; as
     * primeiras [MAX_AI_PAGES] vão também para [images].
     */
    private fun readPdf(
        file: File,
        images: AiPages,
        onPage: (Int, Int) -> Unit,
    ): Pair<List<PageRead>, Int> {
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
            val texts = (0 until total).map { index ->
                onPage(index + 1, total)
                pdf.openPage(index).use { page ->
                    val bitmap = render(page)
                    if (index < MAX_AI_PAGES) images.add(index + 1) { AiImage.fromBitmap(bitmap) }
                    try {
                        orForAi(images.bytes) { recognize(InputImage.fromBitmap(bitmap, 0)) }
                    } finally {
                        // Uma página desenhada tem dezenas de MB: não espera o coletor.
                        bitmap.recycle()
                    }
                }
            }
            texts to pdf.pageCount
        }
    }

    /**
     * As imagens que vão para a IA, e a página de cada uma. Sem [enabled]
     * nada entra: a leitura pediu só o texto.
     */
    private inner class AiPages(private val enabled: Boolean) {
        val bytes = mutableListOf<ByteArray>()
        val pages = mutableListOf<Int>()

        fun add(page: Int, make: () -> ByteArray) {
            if (!enabled) return
            val image = forAi(make) ?: return
            bytes.add(image)
            pages.add(page)
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
    private fun orForAi(images: List<ByteArray>, read: () -> PageRead): PageRead = try {
        read()
    } catch (slow: ReadFailure) {
        if (slow.code != "E-CAPT-07" || images.isEmpty()) throw slow
        PageRead.EMPTY
    }

    private fun recognize(image: InputImage): PageRead = try {
        PageRead.of(Tasks.await(recognizer.process(image), PAGE_TIMEOUT_SECONDS, TimeUnit.SECONDS))
    } catch (slow: TimeoutException) {
        throw ReadFailure("E-CAPT-07")
    }

    private companion object {
        /** Menos que isso não é comprovante lido: é ruído de imagem escura ou pequena. */
        const val MIN_READABLE_CHARS = 8

        /**
         * Um extrato de um mês cabe em 20 páginas (RN-1101). O que passar disso não é lido, e o
         * total real volta junto, para a conversa dizer o que ficou de fora.
         */
        const val MAX_PAGES = 20

        const val RENDER_SIDE = 2000

        /** Quantas páginas de um PDF a IA vê: a de cima do extrato basta quase sempre. */
        const val MAX_AI_PAGES = 3

        /** Página que passa disso é interrompida (ADR-007, item 5). */
        const val PAGE_TIMEOUT_SECONDS = 10L
    }
}
