import 'package:domain/src/receipts/classification_request.dart';
import 'package:domain/src/receipts/entry_proposal.dart';

/// Quem transforma o texto de um comprovante numa proposta de lançamento.
///
/// É uma porta com duas implementações: o classificador por regras, que roda
/// no aparelho e nunca falha, e o que consulta a IA, no servidor. Trocar de
/// fornecedor de IA — ou viver sem IA — não muda quem usa esta interface
/// (ADR-010).
abstract interface class ReceiptClassifier {
  /// A proposta para o comprovante de [request]. Nunca lança por causa do
  /// texto: comprovante ilegível devolve proposta com campos vazios.
  Future<EntryProposal> classify(ClassificationRequest request);
}
