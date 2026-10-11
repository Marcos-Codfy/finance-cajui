import 'package:cajui/src/features/notifications/application/notice_announcement.dart';
import 'package:cajui/src/features/notifications/application/queued_notice.dart';
import 'package:domain/domain.dart';

/// A ida e a volta entre o canal nativo e os tipos da fila (ADR-025).
///
/// O que vem do outro lado é entrada não confiável — o texto da notificação
/// foi escrito por outro app. Campo que falta vira item ilegível, nunca
/// exceção: um item que não abre não pode travar a fila.
abstract final class QueuedNoticeCodec {
  /// O item de [raw]; `null` quando não dá para ler.
  static QueuedNotice? decode(Map<Object?, Object?> raw) {
    final id = raw['id'];
    if (id is! String || id.isEmpty) return null;
    return switch (raw['type']) {
      'bank' => _bank(id, raw),
      'undo' => _undo(id, raw),
      _ => null,
    };
  }

  static QueuedNotice? _bank(String id, Map<Object?, Object?> raw) {
    final packageName = raw['package'];
    final postedAt = raw['postedAt'];
    if (packageName is! String || postedAt is! int) return null;
    final moment = DateTime.fromMillisecondsSinceEpoch(postedAt);
    return BankNotice(
      id: id,
      notification: BankNotification(
        packageName: packageName,
        title: _text(raw['title']),
        text: _text(raw['text']),
        // O dia no fuso do aparelho: é o dia que a pessoa está vivendo.
        postedOn: LocalDate.fromDateTime(moment),
      ),
    );
  }

  static QueuedNotice? _undo(String id, Map<Object?, Object?> raw) {
    final entryId = raw['entryId'];
    if (entryId is! String || entryId.isEmpty) return null;
    return UndoNotice(id: id, entryId: entryId);
  }

  /// O mesmo teto do texto compartilhado: notificação não é livro.
  static String _text(Object? value) {
    final text = value is String ? value : '';
    return text.length > maxTextLength
        ? text.substring(0, maxTextLength)
        : text;
  }

  /// O maior texto lido de uma notificação.
  static const maxTextLength = 2000;

  /// O que vai para o lado nativo postar [announcement].
  static Map<String, Object?> encode(NoticeAnnouncement announcement) =>
      switch (announcement) {
        RecordedAnnouncement(:final entryId) => {
          'kind': 'recorded',
          'entryId': entryId,
          'title': announcement.title,
          'text': announcement.text,
        },
        AskAnnouncement(:final noticeId, :final shareText) => {
          'kind': 'ask',
          'id': noticeId,
          'title': announcement.title,
          'text': announcement.text,
          'shareText': shareText,
        },
      };
}
