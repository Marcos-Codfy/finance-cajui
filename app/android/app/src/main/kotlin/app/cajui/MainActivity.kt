package app.cajui

import android.content.Intent
import app.cajui.capture.CaptureChannel
import app.cajui.auth.DeviceKeyChannel
import app.cajui.capture.PhotoIntake
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

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        capture = CaptureChannel(
            applicationContext,
            flutterEngine.dartExecutor.binaryMessenger,
            PhotoIntake(this),
        )
        DeviceKeyChannel(this, flutterEngine.dartExecutor.binaryMessenger)
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
