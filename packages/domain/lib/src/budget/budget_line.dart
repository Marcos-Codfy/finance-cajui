import 'package:domain/src/budget/line_group.dart';
import 'package:domain/src/ledger/block.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/shared/failure.dart';
import 'package:domain/src/shared/result.dart';
import 'package:meta/meta.dart';

/// Uma linha de "Minhas contas": o que sai todo mês, como na planilha do
/// dono — o que é, quanto, em que grupo e onde se paga.
///
/// O valor é a **estimativa**, e a planilha manda usar o maior: energia que
/// vai de R$ 170 a R$ 200 entra por R$ 200. Zero também vale — "padaria:
/// preencha com o que gastou" —, e aí o mês conta só o que foi gasto.
///
/// A linha aponta para uma categoria: é por ela que o que foi lançado de
/// verdade encontra o que foi previsto, e o mês conta o maior dos dois.
@immutable
final class BudgetLine {
  const new _({
    required this.id,
    required this.name,
    required this.amount,
    required this.group,
    required this.categoryId,
    this.paymentMethodId,
    this.note,
    this.dueDay,
  });

  /// O identificador.
  final String id;

  /// O que é: "Aluguel", "Claude Code", "Uber / transporte".
  final String name;

  /// Quanto, por mês: a estimativa maior. Nunca negativo.
  final Money amount;

  /// Conta fixa, assinatura ou dia a dia.
  final LineGroup group;

  /// A categoria dos lançamentos que realizam esta linha.
  final String categoryId;

  /// Onde se paga — um cartão, boleto, Pix, dinheiro, vale —, quando se
  /// sabe. É só informação: quem decide a moeda de um gasto é o lançamento.
  final String? paymentMethodId;

  /// A observação livre da planilha: "dá para negociar".
  final String? note;

  /// O dia em que vence, quando há.
  final int? dueDay;

  /// O grupo do mês em que a linha entra.
  Block get block => group.block;

  /// Cria a linha, recusando valor negativo.
  static Result<BudgetLine> create({
    required String id,
    required String name,
    required Money amount,
    required LineGroup group,
    required String categoryId,
    String? paymentMethodId,
    String? note,
    int? dueDay,
  }) {
    if (amount.isNegative) return Err(NonPositiveAmount(amount));
    return Ok(
      BudgetLine._(
        id: id,
        name: name.trim(),
        amount: amount,
        group: group,
        categoryId: categoryId,
        paymentMethodId: paymentMethodId,
        note: note == null || note.trim().isEmpty ? null : note.trim(),
        dueDay: dueDay,
      ),
    );
  }
}
