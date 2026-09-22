package app.cajui.capture

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * A ponte entre o módulo nativo de captura e o Dart (ADR-006).
 *
 * O Dart recebe sempre a mesma coisa, venha o compartilhamento com o app
 * fechado ou aberto: um aviso de que chegou algo, e então a lista de itens já
 * copiados para a área privada, na ordem recebida.
 */
class CaptureChannel(
    context: Context,
    messenger: BinaryMessenger,
    private val photos: PhotoIntake? = null,
) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val intake = ShareIntake(context)
    private val ocr = ReceiptOcr(context)
    private val pending = mutableListOf<Map<String, Any?>>()
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var events: EventChannel.EventSink? = null

    init {
        MethodChannel(messenger, "app.cajui/capture").setMethodCallHandler(this)
        EventChannel(messenger, "app.cajui/capture/events").setStreamHandler(this)
    }

    /** Trata a intenção de abertura e as que chegam com o app já aberto. */
    fun handle(intent: Intent?) {
        val received = intake.receive(intent)
        if (received.isEmpty()) return
        pending.addAll(received)
        events?.success(mapOf("type" to "arrived"))
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "takePending" -> result.success(pending.toList()).also { pending.clear() }
            "takePhoto" -> result.success(photos?.start() ?: false)
            "readText" -> readText(call, result)
            "discard" -> result.success(intake.discard(call.argument<String>("path").orEmpty()))
            else -> result.notImplemented()
        }
    }

    /**
     * A foto tirada entra na fila pelo mesmo caminho do compartilhamento: para
     * o Dart, fotografar e compartilhar são a mesma coisa daqui em diante.
     */
    fun onPhoto(requestCode: Int, resultCode: Int) {
        val item = photos?.finish(requestCode, resultCode) ?: return
        pending.add(item)
        events?.success(mapOf("type" to "arrived"))
    }

    /** A leitura sai da thread principal; a resposta e o progresso voltam por ela. */
    private fun readText(call: MethodCall, result: MethodChannel.Result) {
        val path = call.argument<String>("path").orEmpty()
        val kind = call.argument<String>("kind").orEmpty()
        worker.execute {
            try {
                val read = ocr.read(path, kind) { page, of ->
                    main.post { events?.success(mapOf("type" to "progress", "page" to page, "of" to of)) }
                }
                main.post { result.success(read) }
            } catch (failure: ReadFailure) {
                main.post { result.error(failure.code, null, null) }
            } catch (unexpected: Exception) {
                // Arquivo corrompido, imagem que o decodificador recusa: para a pessoa, não deu para ler.
                main.post { result.error("E-CAPT-01", null, null) }
            }
        }
    }

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        events = sink
        if (pending.isNotEmpty()) sink?.success(mapOf("type" to "arrived"))
    }

    override fun onCancel(arguments: Any?) {
        events = null
    }
}
