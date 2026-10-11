import 'package:meta/meta.dart';

/// O que o Cajui avisa depois de ler a notificação de um banco.
///
/// O texto já vem pronto daqui: o lado nativo só desenha a notificação, e a
/// voz do app (guia de voz) fica num lugar só, testável sem aparelho.
@immutable
sealed class NoticeAnnouncement {
  const new({required this.title, required this.text});

  /// A linha de cima: o que aconteceu, com o valor.
  final String title;

  /// A linha de baixo: o que dá para fazer.
  final String text;
}

/// "Lancei R$ 45,90 em Mercado" — com o botão Desfazer (RN-786).
final class RecordedAnnouncement extends NoticeAnnouncement {
  /// Cria o aviso do lançamento [entryId].
  const new({required this.entryId, required super.title, required super.text});

  /// O lançamento que o Desfazer cancela.
  final String entryId;
}

/// "Entrou R$ 150,00 de Fulano. Toque para registrar" (RN-788): o toque
/// abre a conferência de sempre, com [shareText] como se tivesse sido
/// compartilhado.
final class AskAnnouncement extends NoticeAnnouncement {
  /// Cria o pedido de toque para a notificação [noticeId].
  const new({
    required this.noticeId,
    required this.shareText,
    required super.title,
    required super.text,
  });

  /// A notificação de origem: identifica o aviso, para não repetir.
  final String noticeId;

  /// O texto que entra na captura quando a pessoa toca.
  final String shareText;
}
