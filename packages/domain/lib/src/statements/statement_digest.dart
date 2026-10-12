import 'package:domain/src/ledger/payment_method_kind.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/receipts/statement_line_kind.dart';
import 'package:domain/src/statements/line_doubt.dart';
import 'package:domain/src/statements/line_treatment.dart';
import 'package:domain/src/statements/resolved_line.dart';
import 'package:domain/src/statements/statement_block.dart';

/// O extrato lido, organizado para a conversa (RN-1112, RN-1113): os
/// blocos de gasto certo por categoria, as dúvidas, as entradas e o que
/// não conta.
///
/// É refeito a cada resposta: responder lembra (RN-1116), as linhas são
/// resolvidas de novo com a memória nova, e uma resposta só resolve todas
/// as linhas do mesmo lugar.
final class StatementDigest {
  /// Organiza [lines]. [alreadyThere] são as que já estão no Cajui;
  /// [skipped], as que a pessoa tirou nesta conversa sem lembrar.
  factory of(
    List<ResolvedLine> lines, {
    Set<int> alreadyThere = const {},
    Set<int> skipped = const {},
  }) {
    bool counts(int i) => !alreadyThere.contains(i) && !skipped.contains(i);
    final open = [
      for (var i = 0; i < lines.length; i++)
        if (counts(i)) i,
    ];
    final sureExpenses = open.where((i) => _sureExpense(lines[i])).toList();
    return StatementDigest._(
      lines: lines,
      blocks: _blocks(lines, sureExpenses),
      questions: [
        for (final i in open)
          if (!lines[i].isSure && !_isInstallment(lines[i])) i,
      ],
      installments: [
        for (final i in open)
          if (_isInstallment(lines[i])) i,
      ],
      incomes: [
        for (final i in open)
          if (lines[i].isIncome && lines[i].isSure) i,
      ],
      alreadyThere: alreadyThere,
      skipped: skipped,
    );
  }

  const new _({
    required this.lines,
    required this.blocks,
    required this.questions,
    required this.incomes,
    required this.installments,
    required this.alreadyThere,
    required this.skipped,
  });

  /// Todas as linhas lidas, resolvidas.
  final List<ResolvedLine> lines;

  /// Os blocos de gasto certo, do maior para o menor.
  final List<StatementBlock> blocks;

  /// As linhas que pedem pergunta, na ordem do extrato.
  final List<int> questions;

  /// As entradas certas, que viram dinheiro que entrou.
  final List<int> incomes;

  /// As parcelas de compras de outros meses (RN-1111): uma pergunta só,
  /// para todas.
  final List<int> installments;

  /// As que já estavam no Cajui.
  final Set<int> alreadyThere;

  /// As que a pessoa tirou nesta conversa.
  final Set<int> skipped;

  /// As linhas que entram em "Pode lançar": os gastos dos blocos e as
  /// entradas certas. Dúvida sem resposta não entra.
  List<int> get ready => [
    for (final block in blocks) ...block.lines,
    ...incomes,
  ];

  /// As linhas lidas que não contam: fatura, conta sua, alguém da casa e
  /// "não lançar".
  List<int> get leftOut => [
    for (final (i, line) in lines.indexed)
      if (line.isSure && line.isLeftOut && !alreadyThere.contains(i)) i,
  ];

  /// As categorias dos blocos, da mais usada para a menos: a ordem das
  /// sugestões na pergunta de categoria.
  List<String> get rankedCategories => [
    for (final block in blocks) block.categoryId,
  ];

  /// Quantas das linhas fora da conta passam em [test].
  int countLeftOut(bool Function(ResolvedLine line) test) =>
      leftOut.where((i) => test(lines[i])).length;

  /// Fatura paga: nunca gasto (RN-756).
  static bool isCardPayment(ResolvedLine line) =>
      line.treatment == null && line.line.kind == StatementLineKind.cardPayment;

  /// Conta sua ou alguém da casa: dinheiro mudando de lugar (RN-759,
  /// RN-1070).
  static bool isTransfer(ResolvedLine line) =>
      line.treatment == LineTreatment.household ||
      line.treatment == LineTreatment.ownAccount ||
      (line.treatment == null &&
          line.line.kind == StatementLineKind.ownTransfer);

  static bool _isInstallment(ResolvedLine line) =>
      line.doubts.contains(LineDoubt.installment) && line.isExpense;

  /// Quanto as parcelas somam, por moeda.
  ({Money cash, Money voucher}) get installmentTotal =>
      _byTender(lines, installments);

  static bool _sureExpense(ResolvedLine line) =>
      line.isExpense && line.isSure && line.line.categoryId != null;

  static List<StatementBlock> _blocks(List<ResolvedLine> lines, List<int> ids) {
    final byCategory = <String, List<int>>{};
    for (final i in ids) {
      (byCategory[lines[i].line.categoryId!] ??= []).add(i);
    }
    final blocks = [
      for (final MapEntry(:key, :value) in byCategory.entries)
        _block(lines, key, value),
    ];
    // Ordena pelo dinheiro e, no empate, pelo vale: as moedas não se somam
    // nem para ordenar (RN-111).
    return blocks..sort(
      (a, b) => b.cash.cents != a.cash.cents
          ? b.cash.cents.compareTo(a.cash.cents)
          : b.voucher.cents.compareTo(a.voucher.cents),
    );
  }

  static StatementBlock _block(
    List<ResolvedLine> lines,
    String category,
    List<int> ids,
  ) {
    final sorted = [...ids]
      ..sort(
        (a, b) =>
            lines[b].line.amount.cents.compareTo(lines[a].line.amount.cents),
      );
    final (:cash, :voucher) = _byTender(lines, sorted);
    return StatementBlock(
      categoryId: category,
      lines: sorted,
      cash: cash,
      voucher: voucher,
    );
  }

  /// A soma de [ids] em cada moeda, sem nunca juntar as duas (RN-111).
  static ({Money cash, Money voucher}) _byTender(
    List<ResolvedLine> lines,
    Iterable<int> ids,
  ) {
    var cash = Money.zero;
    var voucher = Money.zero;
    for (final i in ids) {
      final line = lines[i].line;
      if (line.paymentKind == PaymentMethodKind.mealVoucher) {
        voucher += line.amount;
      } else {
        cash += line.amount;
      }
    }
    return (cash: cash, voucher: voucher);
  }

  /// Quanto os gastos que contam somam, por moeda: os dos blocos e os que
  /// só falta a categoria — o tipo já é gasto.
  ({Money cash, Money voucher, int count}) get spending {
    final ids = [
      for (final (i, line) in lines.indexed)
        if (_counts(i) &&
            line.isExpense &&
            !line.doubts.contains(LineDoubt.kind) &&
            !_isInstallment(line))
          i,
    ];
    final (:cash, :voucher) = _byTender(lines, ids);
    return (cash: cash, voucher: voucher, count: ids.length);
  }

  /// Quanto entrou, das entradas certas, por moeda: o crédito do vale é
  /// outra moeda (RN-111).
  ({Money cash, Money voucher}) get income => _byTender(lines, incomes);

  bool _counts(int i) => !alreadyThere.contains(i) && !skipped.contains(i);
}
