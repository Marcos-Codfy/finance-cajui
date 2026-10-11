import 'package:domain/domain.dart';

/// Onde os lembretes de vencimento ficam marcados (RN-1081).
///
/// No Android, os alarmes do aparelho, que chegam com o app fechado; na web
/// e nos testes, lugar nenhum — a consulta não avisa nada.
abstract interface class ReminderSchedule {
  /// Se o aparelho marca lembretes. Fora do Android, a linha de Ajustes nem
  /// aparece.
  bool get isSupported;

  /// Troca tudo o que estava marcado por [reminders]. Lista vazia desmarca
  /// tudo: é a chave desligada (RN-1088).
  Future<void> replace(List<DueReminder> reminders);

  /// Se o aparelho deixa o Cajui mostrar notificação. Sem isso, o lembrete
  /// é marcado e não aparece.
  Future<bool> canPost();

  /// Pede para mostrar notificação: a pergunta do Android 13 em diante, ou
  /// a tela do sistema quando a pessoa já disse não.
  Future<void> allowPosting();
}
