import 'package:domain/src/ledger/payment_method_kind.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/money/tender.dart';
import 'package:meta/meta.dart';

/// Uma linha de pagamento: quanto de um lançamento saiu por uma forma de
/// pagamento.
///
/// Um lançamento tem uma ou mais (RN-204) — o caso típico é o vale que acaba
/// no meio da compra. Cada linha pertence a uma moeda só (RN-110): "meio
/// dinheiro, meio vale" são duas linhas.
@immutable
final class PaymentLine {
  /// Cria a linha.
  const new({
    required this.paymentMethodId,
    required this.kind,
    required this.amount,
  });

  /// A forma de pagamento usada.
  final String paymentMethodId;

  /// O tipo da forma de pagamento. Fica na linha porque decide a moeda e o
  /// mês em que a linha conta, e o tipo de uma forma de pagamento não muda.
  final PaymentMethodKind kind;

  /// Quanto saiu por esta forma.
  final Money amount;

  /// A moeda da linha, que é a da forma de pagamento (RN-205).
  Tender get tender => kind.tender;
}
