package app.cajui.voice

import android.app.Activity
import android.content.Intent
import android.speech.RecognizerIntent
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Ditar a pergunta em vez de digitá-la (ADR-018).
 *
 * Quem ouve e transcreve é o **reconhecedor do próprio aparelho**, chamado
 * por intenção — o mesmo caminho da câmera (ADR-017). Por isso o Cajui não
 * pede permissão de microfone, não grava áudio e não guarda áudio: o que
 * volta para cá já é texto.
 *
 * O áudio **nunca vai para o servidor do Cajui nem para a IA**. O que sobe,
 * quando sobe, é a pergunta escrita — igual à digitada, e tratada com a
 * mesma desconfiança.
 */
class SpeechChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private var pending: MethodChannel.Result? = null

    init {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> result.success(canListen())
            "listen" -> listen(result)
            else -> result.notImplemented()
        }
    }

    /** Aparelho sem reconhecedor não mostra o botão, em vez de falhar nele. */
    private fun canListen(): Boolean =
        intent().resolveActivity(activity.packageManager) != null

    private fun listen(result: MethodChannel.Result) {
        if (!canListen()) {
            result.success(null)
            return
        }
        // Duas escutas ao mesmo tempo não existem: a anterior encerra sem
        // texto, como se a pessoa tivesse desistido dela.
        pending?.success(null)
        pending = result
        activity.startActivityForResult(intent(), REQUEST)
    }

    /** O que foi entendido, ou `null` se a pessoa desistiu ou nada saiu. */
    fun onHeard(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != REQUEST) return
        val answer = pending ?: return
        pending = null
        if (resultCode != Activity.RESULT_OK) {
            answer.success(null)
            return
        }
        val heard = data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)
        answer.success(heard?.firstOrNull())
    }

    private fun intent(): Intent =
        Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
            .putExtra(
                RecognizerIntent.EXTRA_LANGUAGE_MODEL,
                RecognizerIntent.LANGUAGE_MODEL_FREE_FORM,
            )
            .putExtra(RecognizerIntent.EXTRA_LANGUAGE, "pt-BR")
            .putExtra(RecognizerIntent.EXTRA_PROMPT, "Fale a sua pergunta")
            // Uma frase por vez: a pessoa está perguntando, não ditando carta.
            .putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)

    private companion object {
        const val CHANNEL = "app.cajui/voice"
        const val REQUEST = 7301
    }
}
