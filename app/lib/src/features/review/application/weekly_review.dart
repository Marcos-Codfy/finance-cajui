import 'package:cajui/src/features/ledger/application/draft_defaults.dart';
import 'package:domain/domain.dart';

/// O que a revisão de domingo traz de volta (RN-870): os gastos dos
/// últimos sete dias que ficaram em Outros ou que o Cajui lançou sozinho
/// pelas notificações do banco, e que ninguém reviu ainda.
///
/// Não é conta: é um filtro sobre o livro, por data, categoria e origem.
abstract final class WeeklyReview {
  /// Quantos dias a revisão olha para trás, contando hoje.
  static const days = 7;

  /// Os lançamentos de [entries] que esperam revisão em [today], fora os
  /// de [reviewed]; os mais recentes primeiro.
  static List<Entry> of(
    Iterable<Entry> entries, {
    required Set<String> reviewed,
    required LocalDate today,
  }) {
    final from = today.addDays(1 - days);
    final waiting = [
      for (final entry in entries)
        if (_isRecent(entry, from, today) &&
            _asksForALook(entry) &&
            !reviewed.contains(entry.id))
          entry,
    ];
    return waiting..sort((a, b) => b.occurredOn.compareTo(a.occurredOn));
  }

  static bool _isRecent(Entry entry, LocalDate from, LocalDate today) =>
      !entry.occurredOn.isBefore(from) && !entry.occurredOn.isAfter(today);

  /// Outros é onde cai o que não tinha categoria; a notificação é o único
  /// lançamento que ninguém conferiu antes de gravar.
  static bool _asksForALook(Entry entry) =>
      entry.categoryId == DraftDefaults.fallbackCategoryId ||
      entry.origin == EntryOrigin.notification;
}
