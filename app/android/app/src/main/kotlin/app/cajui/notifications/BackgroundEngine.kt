package app.cajui.notifications

import android.content.Context
import android.os.Handler
import android.os.Looper
import app.cajui.home.HomeChannel
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * Um motor do Flutter sem janela, para tratar a fila com o app fechado
 * (ADR-025). Roda `notificationMain`, de `main.dart`: o mesmo livro, o
 * mesmo registro cifrado e as mesmas regras do app aberto.
 *
 * Vive o tempo de uma rodada. Acaba quando o Dart avisa que terminou, ou
 * pelo prazo: um motor esquecido gastaria bateria e prenderia o registro.
 */
class BackgroundEngine private constructor(
    private val context: Context,
    private val engine: FlutterEngine,
    private val notices: MethodChannel,
) {

    private val main = Handler(Looper.getMainLooper())

    /**
     * O app abriu: o Dart para na próxima notificação. Se não parar a tempo,
     * a rodada é encerrada — uma linha escrita pela metade é cortada na
     * próxima abertura do registro, e o item volta a ser tratado pelo app.
     */
    fun stop() {
        notices.invokeMethod("stop", null)
        main.postDelayed({ NoticeRouter.finished(this, context) }, STOP_GRACE_MS)
    }

    /** Desliga o motor. Só o [NoticeRouter] chama. */
    fun destroy() {
        main.removeCallbacksAndMessages(null)
        engine.destroy()
    }

    private fun run() {
        val loader = FlutterInjector.instance().flutterLoader()
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(loader.findAppBundlePath(), ENTRYPOINT),
        )
        main.postDelayed({ NoticeRouter.finished(this, context) }, MAX_RUN_MS)
    }

    companion object {
        /** O nome da função em `main.dart`: o contrato com o Dart. */
        const val ENTRYPOINT = "notificationMain"

        /** O máximo de uma rodada: a IA do servidor espera 12 s por item. */
        private const val MAX_RUN_MS = 60_000L

        /** Quanto o app espera a rodada parar quando ele abre. */
        private const val STOP_GRACE_MS = 8_000L

        /** Sobe o motor, liga os canais de que o Dart precisa e começa. */
        fun start(context: Context): BackgroundEngine {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(context)
            loader.ensureInitializationComplete(context, null)
            val engine = FlutterEngine(context)
            val messenger = engine.dartExecutor.binaryMessenger
            val notices = MethodChannel(messenger, NoticeChannel.NAME)
            val background = BackgroundEngine(context, engine, notices)
            NoticeChannel(context, notices, activity = null)
            HomeChannel(context, messenger)
            HeadlessDeviceKey(context, messenger)
            MethodChannel(messenger, BACKGROUND_CHANNEL).setMethodCallHandler { call, result ->
                if (call.method == "finished") NoticeRouter.finished(background, context)
                result.success(null)
            }
            background.run()
            return background
        }

        /** O canal do fim da rodada e da espera do app (`notification_main.dart`). */
        const val BACKGROUND_CHANNEL = "app.cajui/background"
    }
}
