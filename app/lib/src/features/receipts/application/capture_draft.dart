import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/receipts/application/capture.dart';
import 'package:domain/domain.dart';

/// Leva a proposta de uma captura ao rascunho que a tela de conferência
/// mostra.
///
/// O que a proposta resolveu entra; o que ficou em dúvida entra com o
/// **candidato mais provável** já no campo, e os outros ao lado para um
/// toque trocar; a data que não se leu é o dia em que o comprovante chegou.
/// A pessoa confere tudo numa tela e confirma com um toque — é a
/// conferência que o dono pediu para manter, sem campo em branco.
abstract final class CaptureDraft {
  /// O teto da descrição na tela de conferência (RN-775).
  static const maxDescriptionLength = 60;

  /// O rascunho de [capture], com os nomes e formas de pagamento de [book].
  static EntryDraft of(Capture capture, {required LedgerBook book}) {
    final proposal = capture.proposal;
    return EntryDraft(
      captureId: capture.source.id,
      amountCents: proposal.amount.value?.cents ?? 0,
      description: _short(proposal.displayDescription ?? ''),
      category: _categoryOf(
        book,
        proposal.category.value ?? proposal.category.candidates.firstOrNull,
      ),
      method: _methodOf(book, proposal.paymentKind.value),
      // Sem data no comprovante, vale o dia em que ele chegou: quase sempre
      // é o da compra, e a tela mostra o dia marcado para quem quiser trocar.
      occurredOn: proposal.occurredOn.value ?? capture.source.receivedOn,
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
