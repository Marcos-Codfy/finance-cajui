import 'package:domain/src/ledger/possible_duplicate.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/receipts/classification_request.dart';
import 'package:domain/src/receipts/entry_proposal.dart';
import 'package:domain/src/receipts/field_source.dart';
import 'package:domain/src/receipts/merchant_reader.dart';
import 'package:domain/src/receipts/proposed_field.dart';
import 'package:domain/src/receipts/receipt_classifier.dart';
import 'package:domain/src/receipts/receipt_field_reader.dart';

/// O classificador por regras: roda no aparelho, antes de qualquer chamada de
/// rede, e é o que garante que **o app funciona inteiro sem a IA** (RN-752).
///
/// Lê valor, data, forma de pagamento, parcelas e tipo do documento pelas
/// regras fixas, e a categoria pelas regras aprendidas — o que a própria
/// pessoa já ensinou, corrigindo uma proposta.
final class RuleBasedClassifier implements ReceiptClassifier {
  /// Cria o classificador.
  const new();

  @override
  Future<EntryProposal> classify(ClassificationRequest request) async {
    final text = request.text;
    final merchant = MerchantReader.nameIn(text);
    final date = ReceiptFieldReader.dateIn(text, today: request.today);
    final payment = ReceiptFieldReader.paymentKindIn(text);
    return EntryProposal(
      documentKind: ProposedField.resolved(
        ReceiptFieldReader.documentKindIn(text),
        source: FieldSource.fixedRule,
      ),
      amount: _amount(ReceiptFieldReader.amountCandidates(text)),
      occurredOn: date == null
          ? const ProposedField.unread()
          : ProposedField.resolved(date, source: FieldSource.fixedRule),
      category: _category(request, merchant),
      paymentKind: payment == null
          ? const ProposedField.unread()
          : ProposedField.resolved(payment, source: FieldSource.fixedRule),
      merchant: merchant,
      installments: ReceiptFieldReader.installmentsIn(text),
    );
  }

  /// Um candidato só é certeza; vários são dúvida, mostrada como dúvida
  /// (RN-753).
  ProposedField<Money> _amount(List<Money> candidates) => switch (candidates) {
    [] => const ProposedField.unread(),
    [final only] => ProposedField.resolved(only, source: FieldSource.fixedRule),
    _ => ProposedField.undecided(
      candidates.take(3).toList(),
      source: FieldSource.fixedRule,
    ),
  };

  /// A categoria proposta: primeiro a regra que a própria pessoa ensinou
  /// (RN-765), depois o ramo do estabelecimento lido do nome.
  ///
  /// A regra aprendida ganha do ramo de propósito: ela é a correção que a
  /// pessoa já fez, e desfazê-la seria teimosia do app.
  ProposedField<String> _category(
    ClassificationRequest request,
    String? merchant,
  ) {
    if (merchant == null) return const ProposedField.unread();
    final learned = request.learnedRules[PossibleDuplicate.normalize(merchant)];
    if (learned != null && request.categoryById(learned) != null) {
      return ProposedField.resolved(learned, source: FieldSource.learnedRule);
    }
    return _byKind(request, merchant);
  }

  /// O ramo do nome — supermercado, padaria, posto — vira categoria pelo
  /// cadastro. Fica na zona média: é palpite de regra fixa, não certeza.
  ProposedField<String> _byKind(
    ClassificationRequest request,
    String merchant,
  ) {
    final kind = MerchantReader.kindIn(merchant);
    final category = request.categoryByMerchantKind[kind];
    if (category == null || request.categoryById(category) == null) {
      return const ProposedField.unread();
    }
    return ProposedField.undecided([category], source: FieldSource.fixedRule);
  }
}
