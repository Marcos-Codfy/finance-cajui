package app.cajui.notifications

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel

/**
 * Decide quem trata a fila das notificações do banco (ADR-025).
 *
 * O registro cifrado aceita **um escritor por vez**: dois motores do
 * Flutter gravando juntos quebrariam o encadeamento das linhas. Então:
 * com o app aberto, quem trata é ele, avisado pelo canal; com o app
 * fechado, sobe um motor sem janela ([BackgroundEngine]). Se o app abre no
 * meio de uma rodada em segundo plano, a rodada é avisada para parar, e o
 * app só abre o registro quando ela termina ([whenIdle]).
 *
 * Tudo aqui roda na thread principal: é ela que serializa as decisões.
 */
object NoticeRouter {

    private val main = Handler(Looper.getMainLooper())
    private var appChannel: MethodChannel? = null
    private var background: BackgroundEngine? = null
    private val idleWaiters = mutableListOf<() -> Unit>()
    private var pendingRoute: String? = null

    /** O app abriu: daqui em diante, a fila é dele. */
    fun attachApp(channel: MethodChannel) = onMain {
        appChannel = channel
        background?.stop()
    }

    /** O app fechou: a próxima notificação sobe o motor sem janela. */
    fun detachApp(channel: MethodChannel) = onMain {
        if (appChannel === channel) appChannel = null
    }

    /** Chegou algo na fila. */
    fun kick(context: Context) = onMain {
        val channel = appChannel
        if (channel != null) {
            channel.invokeMethod("pending", null)
        } else if (background == null) {
            background = BackgroundEngine.start(context.applicationContext)
        }
    }

    /** Chama [callback] quando não houver rodada em segundo plano. */
    fun whenIdle(callback: () -> Unit) = onMain {
        if (background == null) callback() else idleWaiters.add(callback)
    }

    /**
     * A rodada [engine] acabou — por conta própria ou pelo prazo. O que
     * chegou enquanto ela terminava fica para o app, se ele abriu, ou para
     * **uma** rodada a mais. Uma só: item que derruba a rodada toda vez
     * faria o motor subir sem parar, e ele fica para a próxima notificação
     * ou para quando o app abrir.
     */
    fun finished(engine: BackgroundEngine, context: Context) = onMain {
        if (background !== engine) return@onMain
        engine.destroy()
        background = null
        idleWaiters.toList().forEach { it() }
        idleWaiters.clear()
        val leftovers = NoticeQueue(context).hasItems()
        retried = if (leftovers && retried < MAX_RETRIES) retried + 1 else 0
        if (retried > 0) kick(context)
    }

    private var retried = 0
    private const val MAX_RETRIES = 1

    /**
     * A tela que um aviso tocado pediu. Com o app já aberto, vai na hora;
     * na abertura, fica guardada até o Dart pedir ([takeRoute]).
     */
    fun requestRoute(route: String, appIsRunning: Boolean) = onMain {
        val channel = appChannel
        if (appIsRunning && channel != null) {
            channel.invokeMethod("route", route)
        } else {
            pendingRoute = route
        }
    }

    /** A tela pedida na abertura; quem lê consome. */
    fun takeRoute(): String? = pendingRoute.also { pendingRoute = null }

    /** Sempre depois do que está rodando: nunca destrói um motor de dentro dele. */
    private fun onMain(action: () -> Unit) {
        main.post(action)
    }
}
