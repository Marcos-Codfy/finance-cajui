import 'package:domain/src/calendar/local_date.dart';
import 'package:meta/meta.dart';

/// Uma notificação que chegou de um app de banco, como o Android a entrega.
///
/// É entrada não confiável, igual a um comprovante compartilhado (ADR-025):
/// qualquer app pode escrever qualquer coisa numa notificação, e só o
/// pacote — que o Android garante — diz de onde ela veio.
@immutable
final class BankNotification {
  /// Cria a notificação de [packageName], com [title] e [text], mostrada no
  /// dia [postedOn].
  const new({
    required this.packageName,
    required this.title,
    required this.text,
    required this.postedOn,
  });

  /// O pacote Android do app que notificou.
  final String packageName;

  /// O título. Na carteira do Google, é o nome do estabelecimento.
  final String title;

  /// O texto, já o expandido quando o app manda as duas versões.
  final String text;

  /// O dia em que a notificação chegou: é o dia da movimentação, porque o
  /// banco avisa na hora.
  final LocalDate postedOn;
}
