import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/ledger/payment_method_kind.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/receipts/confidence.dart';
import 'package:domain/src/receipts/statement_line_kind.dart';
import 'package:meta/meta.dart';

/// Uma movimentação lida de um extrato (RN-707): o documento com várias
/// linhas, que vira uma lista para a pessoa marcar o que lançar.
///
/// É só leitura. Nada aqui grava: cada linha marcada vira um lançamento —
/// ou, se é dinheiro que entrou, um recebimento — pelo mesmo caminho de
/// qualquer outro.
@immutable
final class StatementLine {
  /// Cria a linha.
  const new({
    required this.occurredOn,
    required this.description,
    required this.amount,
    this.kind = StatementLineKind.expense,
    this.categoryId,
    this.paymentKind,
    this.doubtful = false,
    this.confidence = Confidence.medium,
    this.page,
    this.sourceLine,
  });

  /// O dia da movimentação.
  final LocalDate occurredOn;

  /// O que o extrato diz que foi, já curto e legível.
  final String description;

  /// O valor, sempre positivo: o sentido está em [kind].
  final Money amount;

  /// O que a movimentação é.
  final StatementLineKind kind;

  /// O palpite de categoria, da lista fechada; `null` quando não houve.
  final String? categoryId;

  /// Por onde saiu, quando o extrato diz: Pix, débito, boleto.
  final PaymentMethodKind? paymentKind;

  /// Se o tipo é só um palpite: a IA disse sem que nenhuma palavra da linha
  /// confirmasse, ou não disse. A linha aparece, dá para marcar, mas nunca
  /// vem marcada — e pagamento de fatura em dúvida pode virar despesa, se a
  /// pessoa marcar (RN-757).
  final bool doubtful;

  /// O quanto a IA confia na categoria. Só a confiança alta decide sozinha
  /// (RN-1109); a leitura antiga não dizia, e conta como média.
  final Confidence confidence;

  /// A página do extrato de onde a linha veio, a partir de 1.
  final int? page;

  /// O número da linha, naquela página, de onde a movimentação saiu. É por
  /// ele que o celular volta ao texto original, sem máscara, que nunca saiu
  /// dele (RN-1106, ADR-030).
  final int? sourceLine;

  /// A mesma linha, paga por [kind]: o extrato do vale não repete "vale" em
  /// cada linha, e a linha sem forma cairia no dinheiro (RN-111).
  StatementLine paidBy(PaymentMethodKind kind) => StatementLine(
    occurredOn: occurredOn,
    description: description,
    amount: amount,
    kind: this.kind,
    categoryId: categoryId,
    paymentKind: kind,
    doubtful: doubtful,
    confidence: confidence,
    page: page,
    sourceLine: sourceLine,
  );
}
