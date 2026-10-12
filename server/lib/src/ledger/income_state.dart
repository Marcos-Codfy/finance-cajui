import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

/// O que **entrou**, reconstruído a partir dos eventos: os recebimentos, os
/// desfeitos e os acertos de saldo do vale.
///
/// Saiu do estado do livro quando o recebimento passou a poder ser desfeito
/// (RN-1120): o desfeito chega como fato do aparelho, e pode chegar antes do
/// próprio recebimento — o celular que desfez sobe os fatos antes de subir
/// o que entrou. Por isso o desfeito fica guardado, e o recebimento que
/// chegar depois dele não entra.
final class IncomeState {
  final Map<String, IncomeReceipt> _receipts = {};
  final Set<String> _cancelled = {};
  final Map<String, Map<String, Object?>> _adjustments = {};

  /// Os recebimentos em vigor, por identificador: o desfeito não está aqui.
  Map<String, IncomeReceipt> get receipts => Map.unmodifiable(_receipts);

  /// Os acertos de saldo do vale, por identificador, como foram gravados.
  Map<String, Map<String, Object?>> get adjustments =>
      Map.unmodifiable(_adjustments);

  /// O recebimento gravado em [payload] passa a valer — a não ser que já
  /// tenha sido desfeito.
  void receive(Map<String, Object?> payload) {
    final receipt = IncomeCodec.decode(payload);
    if (_cancelled.contains(receipt.id)) return;
    _receipts[receipt.id] = receipt;
  }

  /// O recebimento do fato [payload] deixa de valer, para sempre: receber de
  /// novo é um recebimento novo, com outro identificador.
  void cancel(Map<String, Object?> payload) {
    final (:receiptId, on: _) = IncomeCancellationCodec.decode(payload);
    _cancelled.add(receiptId);
    _receipts.remove(receiptId);
  }

  /// O acerto de saldo do vale em [payload] (RN-123).
  void adjust(Map<String, Object?> payload) {
    _adjustments['${payload['id']}'] = payload;
  }

  /// O que entrou em [month], por moeda (RN-111).
  TenderAmounts receivedIn(BudgetMonth month) => _receipts.values
      .where((receipt) => month.contains(receipt.receivedOn))
      .fold(
        TenderAmounts.zero,
        (total, receipt) =>
            total + TenderAmounts.single(receipt.tender, receipt.amount),
      );
}
