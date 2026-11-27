import 'package:cajui/src/features/ledger/application/entry_draft.dart';

/// O que falta para lançar, escrito no próprio botão "Lançar": botão
/// apagado sem motivo deixa a pessoa procurando o erro (27/11/2026).
abstract final class EntryFormMissing {
  /// O que falta em [draft], ou `null` quando não falta nada.
  static String? of(EntryDraft draft) => switch (draft) {
    EntryDraft(amountCents: <= 0) => 'Falta o valor',
    EntryDraft(occurredOn: null) => 'Falta a data',
    _ when !draft.isComplete => 'Falta a segunda forma de pagamento',
    _ => null,
  };
}
