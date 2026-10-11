package app.cajui.home

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import app.cajui.MainActivity
import app.cajui.R

/**
 * O widget da tela inicial (ADR-025): quanto ainda dá para gastar na
 * semana, e a câmera e a galeria a um toque.
 *
 * O número é o último que o app publicou. Passada a semana a que ele se
 * refere, o widget não o mostra: pede para abrir o app, que publica o novo.
 */
class HomeWidget : AppWidgetProvider() {

    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        manager.updateAppWidget(ids, views(context))
    }

    companion object {
        /** Redesenha todos os widgets do Cajui na tela inicial. */
        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context) ?: return
            val ids = manager.getAppWidgetIds(ComponentName(context, HomeWidget::class.java))
            if (ids.isNotEmpty()) manager.updateAppWidget(ids, views(context))
        }

        private fun views(context: Context): RemoteViews {
            val store = HomeSnapshotStore(context)
            val views = RemoteViews(context.packageName, R.layout.home_widget)
            if (store.exists && store.isCurrent()) {
                views.setTextViewText(R.id.home_label, store.label)
                views.setTextViewText(R.id.home_amount, store.amount)
                views.setTextViewText(R.id.home_caption, store.caption)
            } else {
                views.setTextViewText(R.id.home_label, context.getString(R.string.home_widget_stale_label))
                views.setTextViewText(R.id.home_amount, context.getString(R.string.home_widget_stale_amount))
                views.setTextViewText(R.id.home_caption, context.getString(R.string.home_widget_stale_caption))
            }
            views.setOnClickPendingIntent(R.id.home_root, open(context, Intent.ACTION_MAIN, 0))
            views.setOnClickPendingIntent(R.id.home_camera, open(context, MainActivity.ACTION_PHOTO, 1))
            views.setOnClickPendingIntent(R.id.home_gallery, open(context, MainActivity.ACTION_PICK, 2))
            return views
        }

        /** Abre o app já na câmera, já na galeria, ou só abre. */
        private fun open(context: Context, action: String, requestCode: Int): PendingIntent {
            val intent = Intent(context, MainActivity::class.java)
                .setAction(action)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            return PendingIntent.getActivity(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
        }
    }
}
