import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/money/money.dart';
import 'package:meta/meta.dart';

/// Uma linha da aba "Lançamentos" do mês exportado (RN-1090): um lançamento,
/// ou um estorno.
///
/// Dinheiro e vale vêm em colunas separadas e nunca se somam, nem aqui nem
/// na planilha (RN-111): quem abrir o arquivo no Excel e somar a coluna do
/// dinheiro tem o dinheiro, e só ele.
@immutable
final class ExportRow {
  /// Cria a linha.
  const new({
    required this.on,
    required this.description,
    required this.category,
    required this.group,
    required this.method,
    required this.cash,
    required this.voucher,
    this.installments,
    this.isReversal = false,
  });

  /// O dia da compra, ou o dia em que o estorno voltou.
  final LocalDate on;

  /// O que foi: "Padaria Central", ou "Estorno: Padaria Central".
  final String description;

  /// O nome da categoria.
  final String category;

  /// O grupo da planilha: "Contas fixas", "Assinaturas", "Dia a dia" ou
  /// "Parcelas de dívida".
  final String group;

  /// Por onde saiu: o nome da forma de pagamento, ou das formas, juntas.
  final String method;

  /// A parte em dinheiro. Negativa no estorno.
  final Money cash;

  /// A parte em vale. Negativa no estorno.
  final Money voucher;

  /// Em quantas vezes, quando a compra foi parcelada no cartão.
  final int? installments;

  /// Se a linha é um estorno — o dinheiro que voltou.
  final bool isReversal;
}
