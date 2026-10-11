import 'dart:async';

import 'package:cajui/src/core/settings/preferences_store.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Qual mês já ganhou a festa de fechar no verde (escolha 5 do dono).
///
/// A festa é uma vez por mês: se rodasse a cada abertura, o brilho viraria
/// enfeite de sempre. Marcar **não** reconstrói a tela — a festa que está
/// acontecendo não é cortada no meio por ter sido anotada.
final class MonthCelebration {
  /// Cria a memória da festa sobre o lugar das preferências.
  new(this._store) : _done = _store.read().celebratedMonth;

  final PreferencesStore _store;
  String? _done;
  String? _started;

  /// Se o Início mostra [month] em festa. A festa começa na primeira vez
  /// que o mês no verde fica **à vista** ([visible]) — o Início monta por
  /// baixo da conversa, e festa que ninguém vê não conta — e, começada,
  /// fica assim até o app fechar, para a tela não recomeçá-la ao voltar.
  bool party(BudgetMonth month, {required bool visible}) {
    final key = _key(month);
    if (_started == key) return true;
    return visible && _done != key;
  }

  /// Anota que a festa de [month] começou.
  void mark(BudgetMonth month) {
    final key = _key(month);
    if (_started == key) return;
    _started = key;
    if (_done == key) return;
    _done = key;
    unawaited(
      _store.update((current) => current.copyWith(celebratedMonth: key)),
    );
  }

  static String _key(BudgetMonth month) =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';
}

/// A memória da festa, uma por app aberto.
final monthCelebrationProvider = Provider<MonthCelebration>(
  (ref) => MonthCelebration(ref.watch(preferencesStoreProvider)),
);
