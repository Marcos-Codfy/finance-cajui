package app.cajui.home

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService
import androidx.annotation.RequiresApi
import app.cajui.MainActivity

/**
 * O "Gastei" da barra rápida do Android: um toque no painel que desce do
 * topo abre o Novo gasto, sem procurar o app nem o widget (27/11/2026).
 *
 * É um atalho, não um interruptor: o bloco fica sempre "ligado", e o toque
 * só abre o app pela mesma rota do "+" do widget.
 */
@RequiresApi(Build.VERSION_CODES.N)
class SpendTileService : TileService() {

    override fun onStartListening() {
        qsTile?.apply {
            state = Tile.STATE_ACTIVE
            updateTile()
        }
    }

    override fun onClick() {
        val intent = Intent(this, MainActivity::class.java)
            .setAction(MainActivity.ACTION_NEW_ENTRY)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val pending = PendingIntent.getActivity(
                this,
                REQUEST_CODE,
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            startActivityAndCollapse(pending)
        } else {
            collapseWithIntent(intent)
        }
    }

    /** Até o Android 13, o atalho abre o app pela intenção direta. */
    @SuppressLint("StartActivityAndCollapseDeprecated")
    @Suppress("DEPRECATION")
    private fun collapseWithIntent(intent: Intent) = startActivityAndCollapse(intent)

    private companion object {
        /** Diferente dos do widget (0 a 3), para um não substituir o outro. */
        const val REQUEST_CODE = 10
    }
}
