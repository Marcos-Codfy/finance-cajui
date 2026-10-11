package app.cajui.notifications

import android.app.Activity
import android.content.Context
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * O canal `app.cajui/notifications` (ADR-025): o que o Dart pede ao lado
 * nativo — a fila, os avisos, o acesso às notificações e a tela pedida na
 * abertura.
 *
 * Existe um por motor: o do app aberto, com a atividade para pedir
 * permissão, e o do motor sem janela, sem ela.
 */
class NoticeChannel(
    private val context: Context,
    channel: MethodChannel,
    private val activity: Activity?,
) : MethodChannel.MethodCallHandler {

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "take" -> result.success(NoticeQueue(context).all())
                "ack" -> ack(call, result)
                "announce" -> announce(call, result)
                "isGranted" -> result.success(NotificationAccess.isGranted(context))
                "openSettings" -> openSettings(result)
                "takeRoute" -> result.success(NoticeRouter.takeRoute())
                else -> result.notImplemented()
            }
        } catch (failure: Exception) {
            // Só o tipo: o que atravessa este canal tem valor e nome (RN-797).
            Log.w(TAG, "pedido recusado: ${failure.javaClass.simpleName}")
            result.error("E-APP-01", failure.javaClass.simpleName, null)
        }
    }

    private fun ack(call: MethodCall, result: MethodChannel.Result) {
        val ids = call.argument<List<String>>("ids").orEmpty().toSet()
        NoticeQueue(context).remove(ids)
        result.success(null)
    }

    private fun announce(call: MethodCall, result: MethodChannel.Result) {
        val arguments = call.arguments as? Map<*, *> ?: emptyMap<String, Any>()
        NoticePoster(context).announce(arguments)
        result.success(null)
    }

    /** Só o app aberto tem atividade para pedir permissão e abrir telas. */
    private fun openSettings(result: MethodChannel.Result) {
        activity?.let(NotificationAccess::open)
        result.success(null)
    }

    companion object {
        /** O nome do canal: o contrato com `native_notifications_channel.dart`. */
        const val NAME = "app.cajui/notifications"
        private const val TAG = "cajui-notices"
    }
}
