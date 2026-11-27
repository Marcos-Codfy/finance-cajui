package app.cajui.home

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context

/**
 * O widget do vale alimentação (2×1): o saldo do vale, ou o vale do mês do
 * plano. O vale é outra moeda e nunca se soma ao dinheiro (RN-111): por
 * isso tem widget próprio, ao lado do do mês, e não uma linha dentro dele.
 */
class HomeWidgetVoucher : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        manager.updateAppWidget(ids, HomeWidgetViews.voucher(context))
    }
}
