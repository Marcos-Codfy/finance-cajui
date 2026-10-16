package app.cajui.home

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context

/**
 * O widget grande da tela inicial (ADR-025, 4×2): o número do mês — a
 * sobra, ou o que já saiu —, as próximas contas a vencer, e o lançar à mão,
 * a câmera e a galeria a um toque.
 *
 * É de vidro sobre a aurora (pedido do dono, 12/10). O nome da classe é o
 * de antes de haver dois tamanhos: trocá-lo tiraria da tela inicial o
 * widget de quem já o pôs.
 */
class HomeWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        manager.updateAppWidget(ids, HomeWidgetViews.large(context))
    }

    companion object {
        /** Redesenha todos os widgets do Cajui na tela inicial, dos dois tamanhos. */
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context) ?: return
            val large = manager.getAppWidgetIds(ComponentName(context, HomeWidget::class.java))
            if (large.isNotEmpty()) manager.updateAppWidget(large, HomeWidgetViews.large(context))
            val small = manager.getAppWidgetIds(ComponentName(context, HomeWidgetSmall::class.java))
            if (small.isNotEmpty()) manager.updateAppWidget(small, HomeWidgetViews.small(context))
        }

        /** Se há algum widget do Cajui na tela inicial, de qualquer tamanho. */
        fun isPlaced(context: Context, manager: AppWidgetManager): Boolean =
            listOf(HomeWidget::class.java, HomeWidgetSmall::class.java).any {
                manager.getAppWidgetIds(ComponentName(context, it)).isNotEmpty()
            }
    }
}
