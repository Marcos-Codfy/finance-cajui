import 'package:cajui/src/features/notifications/application/notice_announcement.dart';
import 'package:cajui/src/features/notifications/application/queued_notice.dart';

/// O lado do aparelho das notificações do banco (ADR-025): a fila que o
/// leitor de notificações do Android enche, e os avisos que o Cajui posta.
///
/// É uma porta: no Android, o canal `app.cajui/notifications`; na web e nos
/// testes, nada chega e nada sai.
abstract interface class BankNoticeDevice {
  /// Um aviso a cada vez que algo entra na fila com o app aberto.
  Stream<void> get arrivals;

  /// O que está na fila, na ordem em que chegou. Nada sai dela até [ack]:
  /// se o app fechar no meio, o resto é tratado na próxima vez.
  Future<List<QueuedNotice>> take();

  /// Tira da fila o que já foi tratado.
  Future<void> ack(Iterable<String> ids);

  /// Posta a notificação do Cajui.
  Future<void> announce(NoticeAnnouncement announcement);

  /// Se o lado nativo pediu para parar: o app abriu enquanto a leitura em
  /// segundo plano gravava, e o registro só aceita um escritor por vez.
  bool get stopRequested;
}
