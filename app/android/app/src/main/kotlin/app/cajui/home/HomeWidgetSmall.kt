package app.cajui.home

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context

/**
 * O widget pequeno da tela inicial (2×1): só o número do mês, para quem
 * quer a sobra à vista sem ceder meia tela. O toque abre o app pela mesma
 * chegada do grande; os atalhos e as contas ficam no grande.
 *
 * É outro provedor, e não o grande encolhido: assim os dois aparecem
 * separados na lista de widgets, cada um com a sua prévia.
 */
class HomeWidgetSmall : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        manager.updateAppWidget(ids, HomeWidgetViews.small(context))
    }
}
