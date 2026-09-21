import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// Os estados da tela de lançar à mão. A tela faz `switch` exaustivo sobre
/// eles: estado novo sem desenho não compila (ADR-002).
@immutable
sealed class EntryFormState {
  const new(this.draft);

  /// O que já foi preenchido.
  final EntryDraft draft;
}

/// A pessoa está preenchendo. Se uma regra recusou a última tentativa,
/// [problem] diz qual — e fica na tela até ser resolvido (RNF-A11Y-13).
final class EntryFormEditing extends EntryFormState {
  /// Cria o estado de edição de [draft].
  const new(super.draft, {this.problem});

  /// A recusa a resolver, se houver.
  final PresentedError? problem;
}

/// O lançamento está sendo gravado. O botão segura o segundo toque.
final class EntryFormSaving extends EntryFormState {
  /// Cria o estado de gravação de [draft].
  const new(super.draft);
}

/// Gravado. A tela fecha e a lista já mostra o [entry].
final class EntryFormSaved extends EntryFormState {
  /// Cria o estado final, com o lançamento [entry] gravado.
  const new(super.draft, this.entry);

  /// O lançamento que ficou gravado.
  final Entry entry;
}
