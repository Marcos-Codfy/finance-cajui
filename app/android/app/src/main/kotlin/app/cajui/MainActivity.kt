package app.cajui

import android.content.Intent
import app.cajui.capture.CaptureChannel
import app.cajui.auth.DeviceKeyChannel
import app.cajui.capture.PhotoIntake
import app.cajui.voice.SpeechChannel
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * A única atividade do app. Abertura a frio e app já aberto passam pelo mesmo
 * caminho de captura: a intenção inicial é lida quando o motor sobe, e as
 * seguintes chegam por `onNewIntent` (ADR-006). A foto tirada pela câmera do
 * aparelho volta por `onActivityResult` e entra na mesma fila (ADR-017).
 */
// `FlutterFragmentActivity`, e não `FlutterActivity`: a caixa de diálogo da
// biometria é um fragmento, e só existe sobre uma atividade que os hospede.
class MainActivity : FlutterFragmentActivity() {

    private var capture: CaptureChannel? = null
    private var speech: SpeechChannel? = null

    /**
     * A tela não vai para a miniatura do seletor de apps, e não se deixa
     * fotografar nem gravar (T-07).
     *
     * O Android guarda uma imagem da última tela de cada app para mostrar no
     * seletor — e essa imagem ficaria com o saldo e os gastos à vista de
     * quem pegasse o celular desbloqueado, sem precisar abrir nada.
     */
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        window.setFlags(
            android.view.WindowManager.LayoutParams.FLAG_SECURE,
            android.view.WindowManager.LayoutParams.FLAG_SECURE,
        )
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        capture = CaptureChannel(applicationContext, messenger, PhotoIntake(this))
        speech = SpeechChannel(this, messenger)
        DeviceKeyChannel(this, messenger)
        capture?.handle(intent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        capture?.onPhoto(requestCode, resultCode)
        speech?.onHeard(requestCode, resultCode, data)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        capture?.handle(intent)
    }
}
