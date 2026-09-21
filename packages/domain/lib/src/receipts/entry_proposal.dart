import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/ledger/payment_method_kind.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/receipts/document_kind.dart';
import 'package:domain/src/receipts/proposed_field.dart';
import 'package:meta/meta.dart';

/// A proposta de lançamento lida de um comprovante (RN-740).
///
/// É só uma proposta. Nada aqui grava coisa alguma: o que vira lançamento é
/// o que a pessoa confirma na tela, e a confirmação sempre aparece (RN-795).
@immutable
final class EntryProposal {
  /// Cria a proposta.
  const new({
    required this.documentKind,
    required this.amount,
    required this.occurredOn,
    required this.category,
    required this.paymentKind,
    this.merchant,
    this.installments,
    this.warnings = const [],
  });

  /// O que o comprovante é. Só `purchase` segue para a confirmação de
  /// despesa.
  final ProposedField<DocumentKind> documentKind;

  /// O valor.
  final ProposedField<Money> amount;

  /// A data da compra.
  final ProposedField<LocalDate> occurredOn;

  /// A categoria, pelo identificador. O bloco não é campo: é o da categoria
  /// (RN-202), diga a IA o que disser.
  final ProposedField<String> category;

  /// Por onde foi pago.
  final ProposedField<PaymentMethodKind> paymentKind;

  /// O estabelecimento, como lido.
  final String? merchant;

  /// Em quantas vezes, quando o texto fala em parcelas.
  final int? installments;

  /// Códigos do catálogo que explicam por que a IA não participou:
  /// `E-AI-01`, `E-AI-03`, `E-AI-04`. A proposta continua válida.
  final List<String> warnings;

  /// A mesma proposta, com [category] e [warnings] trocados.
  EntryProposal copyWith({
    ProposedField<String>? category,
    ProposedField<Money>? amount,
    ProposedField<DocumentKind>? documentKind,
    List<String>? warnings,
  }) => EntryProposal(
    documentKind: documentKind ?? this.documentKind,
    amount: amount ?? this.amount,
    occurredOn: occurredOn,
    category: category ?? this.category,
    paymentKind: paymentKind,
    merchant: merchant,
    installments: installments,
    warnings: warnings ?? this.warnings,
  );
}
