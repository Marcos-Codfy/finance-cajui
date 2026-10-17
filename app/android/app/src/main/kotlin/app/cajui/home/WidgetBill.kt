package app.cajui.home

/**
 * Uma conta a vencer no widget grande, como o Dart a escreveu: o nome, o
 * dia em ISO e o dia já em palavras ("vence dia 10").
 *
 * O dia em ISO serve só para tirar da lista a conta que já venceu quando o
 * app fica dias sem abrir. Datas em ISO comparam como texto.
 */
data class WidgetBill(val name: String, val dueOn: String, val day: String)
