import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/receipts/application/capture.dart';
import 'package:domain/domain.dart';

/// Leva a proposta de uma captura ao rascunho que a tela de conferência
/// mostra.
///
/// Só entra no rascunho o que a proposta **resolveu**. Campo em dúvida fica
/// vazio, com os candidatos ao lado, e campo não lido fica vazio e pronto: o
/// app não chuta para parecer esperto (sharing-flow, zonas de confiança).
abstract final class CaptureDraft {
  /// O teto da descrição na tela de conferência (RN-775).
  static const maxDescriptionLength = 60;

  /// O rascunho de [capture], com os nomes e formas de pagamento de [book].
  static EntryDraft of(
    Capture capture, {
    required LedgerBook book,
    required LocalDate today,
  }) {
    final proposal = capture.proposal;
    return EntryDraft(
      captureId: capture.source.id,
      amountCents: proposal.amount.value?.cents ?? 0,
      description: _short(proposal.displayDescription ?? ''),
      category: _categoryOf(book, proposal.category.value),
      method: _methodOf(book, proposal.paymentKind.value),
      occurredOn: proposal.occurredOn.value ?? today,
    );
  }

  static String _short(String text) {
    final line = text.trim();
    if (line.length <= maxDescriptionLength) return line;
    return line.substring(0, maxDescriptionLength).trimRight();
  }

  static Category? _categoryOf(LedgerBook book, String? id) {
    for (final category in book.categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  /// A primeira forma cadastrada do tipo lido. Sem cartão de crédito
  /// cadastrado, "crédito" no comprovante deixa o campo para a pessoa.
  static PaymentMethod? _methodOf(LedgerBook book, PaymentMethodKind? kind) {
    for (final method in book.methods) {
      if (method.kind == kind) return method;
    }
    return null;
  }
}
