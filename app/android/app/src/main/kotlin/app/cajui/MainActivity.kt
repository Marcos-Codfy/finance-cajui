package app.cajui

import android.content.Intent
import app.cajui.capture.CaptureChannel
import app.cajui.capture.PhotoIntake
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * A única atividade do app. Abertura a frio e app já aberto passam pelo mesmo
 * caminho de captura: a intenção inicial é lida quando o motor sobe, e as
 * seguintes chegam por `onNewIntent` (ADR-006). A foto tirada pela câmera do
 * aparelho volta por `onActivityResult` e entra na mesma fila (ADR-017).
 */
class MainActivity : FlutterActivity() {

    private var capture: CaptureChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        capture = CaptureChannel(
            applicationContext,
            flutterEngine.dartExecutor.binaryMessenger,
            PhotoIntake(this),
        )
        capture?.handle(intent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        capture?.onPhoto(requestCode, resultCode)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        capture?.handle(intent)
    }
}
