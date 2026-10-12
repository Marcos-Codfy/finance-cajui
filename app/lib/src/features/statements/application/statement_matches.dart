import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:domain/domain.dart';

/// As linhas do extrato que já estão no Cajui (RN-1112): o gasto que entrou
/// pela notificação do banco ou pelo comprovante, e o que este extrato já
/// lançou antes.
///
/// Cada linha casa com no máximo um lançamento, e cada lançamento com no
/// máximo uma linha: duas compras de R$ 8,00 na padaria no mesmo dia, com
/// uma só lançada, deixam a outra entrar. O nome conta quando os dois lados
/// têm um: um Uber de R$ 25,00 já lançado não esconde a farmácia de R$ 25,00
/// do dia seguinte. A parcela de uma compra parcelada já lançada também
/// está lá — o plano do cartão já a conta (RN-1111).
abstract final class StatementMatches {
  /// Os índices de [lines] que já estão em [book].
  static Set<int> of(List<ResolvedLine> lines, LedgerBook book) {
    final used = <String>{};
    return {
      for (final (index, line) in lines.indexed)
        if (_claim(line, book, used)) index,
    };
  }

  /// A diferença de dias aceita entre a linha e o lançamento: o banco
  /// registra a compra no débito um ou dois dias depois.
  static const window = 2;

  static bool _claim(ResolvedLine line, LedgerBook book, Set<String> used) {
    final id = line.isIncome
        ? _receipt(line, book, used)
        : _entry(line, book, used);
    if (id == null) return false;
    used.add(id);
    return true;
  }

  static String? _entry(ResolvedLine line, LedgerBook book, Set<String> used) {
    final mark = line.installment;
    if (mark != null && mark.number > 1) {
      return _installmentOf(line, mark, book, used);
    }
    final on = line.line.occurredOn;
    final candidates = [
      for (final entry in book.entries)
        if (!used.contains(entry.id) &&
            entry.amount == line.line.amount &&
            _near(entry.occurredOn, on) &&
            _sameName(entry.description, line))
          entry,
    ]..sort((a, b) => _gap(a.occurredOn, on).compareTo(_gap(b.occurredOn, on)));
    return candidates.firstOrNull?.id;
  }

  /// A parcela casa com a compra parcelada de mesmo nome, em tantas vezes
  /// quanto a linha diz, com uma parcela do mesmo valor (dois centavos de
  /// arredondamento).
  static String? _installmentOf(
    ResolvedLine line,
    InstallmentMark mark,
    LedgerBook book,
    Set<String> used,
  ) {
    bool fits(Entry entry) {
      final plan = entry.installmentPlan;
      return plan != null &&
          plan.count == mark.total &&
          plan.installments.any(
            (part) => (part.amount.cents - line.line.amount.cents).abs() <= 2,
          );
    }

    return book.entries
        .where(
          (entry) =>
              !used.contains(entry.id) &&
              fits(entry) &&
              _sameName(entry.description, line),
        )
        .firstOrNull
        ?.id;
  }

  static String? _receipt(
    ResolvedLine line,
    LedgerBook book,
    Set<String> used,
  ) => book.receipts
      .where(
        (receipt) =>
            !used.contains(receipt.id) &&
            receipt.amount == line.line.amount &&
            _near(receipt.receivedOn, line.line.occurredOn),
      )
      .firstOrNull
      ?.id;

  static bool _near(LocalDate a, LocalDate b) => _gap(a, b) <= window;

  static int _gap(LocalDate a, LocalDate b) => a.daysUntil(b).abs();

  /// Os nomes batem quando dividem uma palavra que identifica o lugar. Se
  /// um dos lados não tem nome — "Compra no débito", "Pix" —, não há como
  /// dizer que é outro lugar, e vale o valor e o dia.
  static bool _sameName(String recorded, ResolvedLine line) {
    final mine = _words(recorded);
    final theirs = {
      ..._words(line.line.description),
      ..._words(line.contentKey),
    };
    if (mine.isEmpty || theirs.isEmpty) return true;
    return mine.intersection(theirs).isNotEmpty;
  }

  static Set<String> _words(String text) => {
    for (final word in MerchantBrand.keyOf(text).split(' '))
      if (word.length >= 3 && !_generic.contains(word)) word,
  };

  /// Palavras que o banco escreve em qualquer linha e não dizem o lugar.
  static const _generic = {
    'compra',
    'debito',
    'credito',
    'cartao',
    'pix',
    'enviado',
    'recebido',
    'pagamento',
    'transferencia',
    'transf',
    'gasto',
    'lancamento',
    'para',
    'com',
    'loja',
    'movimentacao',
  };
}
