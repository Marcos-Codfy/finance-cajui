import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/money/tender.dart';
import 'package:meta/meta.dart';

/// Um recebimento: dinheiro ou vale que de fato entrou.
///
/// Com [sourceId], é a renda de uma fonte naquele mês, e o valor recebido
/// substitui o esperado nos cálculos (RN-131). Sem fonte, é uma **entrada
/// avulsa** — a venda de um objeto, um empréstimo devolvido —, que conta só
/// no mês em que ocorre e nunca é projetada para os seguintes (RN-133).
@immutable
final class IncomeReceipt {
  /// Cria o recebimento.
  const new({
    required this.id,
    required this.tender,
    required this.amount,
    required this.receivedOn,
    this.sourceId,
    this.note,
  });

  /// O identificador do recebimento.
  final String id;

  /// A fonte de renda a que pertence; nulo para entrada avulsa.
  final String? sourceId;

  /// A moeda em que entrou.
  final Tender tender;

  /// Quanto entrou.
  final Money amount;

  /// O dia em que entrou; define o mês de competência.
  final LocalDate receivedOn;

  /// É uma entrada avulsa, sem fonte.
  bool get isOneOff => sourceId == null;

  /// O que foi, na entrada avulsa: "Saldo da conta", "Venda do sofá". Dá
  /// nome ao dinheiro que não é salário (16/10/2026); não muda conta
  /// nenhuma — saldo e extra entram igual no dinheiro do mês.
  final String? note;
}
