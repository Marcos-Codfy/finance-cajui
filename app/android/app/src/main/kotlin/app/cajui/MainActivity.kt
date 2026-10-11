package app.cajui

import android.content.Intent
import app.cajui.auth.DeviceKeyChannel
import app.cajui.capture.CaptureChannel
import app.cajui.capture.FileIntake
import app.cajui.capture.PhotoIntake
import app.cajui.home.HomeChannel
import app.cajui.notifications.BackgroundEngine
import app.cajui.notifications.NoticeChannel
import app.cajui.notifications.NoticeRouter
import app.cajui.notifications.NotificationAccess
import app.cajui.voice.SpeechChannel
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * A única atividade do app. Abertura a frio e app já aberto passam pelo mesmo
 * caminho de captura: a intenção inicial é lida quando o motor sobe, e as
 * seguintes chegam por `onNewIntent` (ADR-006). A foto tirada pela câmera do
 * aparelho e o que foi escolhido no seletor de arquivos voltam por
 * `onActivityResult` e entram na mesma fila (ADR-017). Os botões do widget e
 * o aviso de domingo também chegam como intenção (ADR-025).
 */
// `FlutterActivity` de novo (ADR-024): a `FlutterFragmentActivity` existia
// para hospedar a caixa de diálogo da biometria, que saiu com a chave da
// casa. Câmera, seletor de arquivos e ditado pedem só uma `Activity`.
class MainActivity : FlutterActivity() {

    private var capture: CaptureChannel? = null
    private var speech: SpeechChannel? = null
    private var notices: MethodChannel? = null
    private val photos by lazy { PhotoIntake(this) }
    private val files by lazy { FileIntake(this) }
    private var restored = false

    /**
     * A tela se deixa fotografar e gravar, e aparece na miniatura do seletor
     * de apps. Até 11/10/2026 o `FLAG_SECURE` impedia os três (T-07); o dono
     * pediu print e gravação ("não existe nenhum dado sensível"), e o risco
     * da miniatura com os números à vista ficou aceito por ele.
     */
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        // Recriada depois de o sistema matar o processo, a atividade recebe a
        // mesma intenção de antes: o botão de câmera do widget não pode abrir
        // a câmera de novo sozinho.
        restored = savedInstanceState != null
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        capture = CaptureChannel(applicationContext, messenger, photos, files)
        speech = SpeechChannel(this, messenger)
        DeviceKeyChannel(messenger)
        configureOutside(messenger)
        capture?.handle(intent)
        if (!restored) handleShortcut(intent, appIsRunning = false)
    }

    /**
     * O que liga o app aberto ao que acontece fora dele (ADR-025): a fila das
     * notificações do banco passa a ser dele, o widget recebe o retrato, e a
     * abertura espera a leitura em segundo plano que estiver gravando.
     */
    private fun configureOutside(messenger: BinaryMessenger) {
        val channel = MethodChannel(messenger, NoticeChannel.NAME)
        NoticeChannel(applicationContext, channel, this)
        HomeChannel(applicationContext, messenger)
        MethodChannel(messenger, BackgroundEngine.BACKGROUND_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "waitIdle") {
                NoticeRouter.whenIdle { result.success(null) }
            } else {
                result.notImplemented()
            }
        }
        NoticeRouter.attachApp(channel)
        notices = channel
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        notices?.let(NoticeRouter::detachApp)
        notices = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        capture?.onPhoto(requestCode, resultCode)
        capture?.onPicked(requestCode, resultCode, data)
        speech?.onHeard(requestCode, resultCode, data)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        NotificationAccess.onPermissionResult(this, requestCode)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        capture?.handle(intent)
        handleShortcut(intent, appIsRunning = true)
    }

    /**
     * Os atalhos de fora: a câmera e a galeria do widget abrem o mesmo
     * caminho do botão de dentro do app (ADR-017); o aviso de domingo abre a
     * revisão da semana, e não o painel (RN-849).
     */
    private fun handleShortcut(intent: Intent?, appIsRunning: Boolean) {
        when (intent?.action) {
            ACTION_PHOTO -> photos.start()
            ACTION_PICK -> files.start()
            ACTION_REVIEW -> NoticeRouter.requestRoute(REVIEW_ROUTE, appIsRunning)
        }
    }

    companion object {
        const val ACTION_PHOTO = "app.cajui.action.PHOTO"
        const val ACTION_PICK = "app.cajui.action.PICK"
        const val ACTION_REVIEW = "app.cajui.action.REVIEW"

        /** O contrato com `NotificationsHost.reviewRoute`, no Dart. */
        private const val REVIEW_ROUTE = "review"
    }
}
