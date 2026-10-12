import 'package:domain/src/calendar/calendar_words.dart';
import 'package:domain/src/calendar/local_date.dart';
import 'package:domain/src/money/money.dart';
import 'package:domain/src/money/money_format.dart';
import 'package:domain/src/statements/line_treatment.dart';
import 'package:domain/src/statements/resolved_line.dart';
import 'package:domain/src/statements/statement_block.dart';
import 'package:domain/src/statements/statement_digest.dart';
import 'package:domain/src/statements/statement_question.dart';

/// O que a Juju diz durante o extrato (RN-1112 a RN-1119).
///
/// As frases moram no domínio, como as do retorno periódico (RN-802): cada
/// número dito sai da mesma conta que a tela mostra, e o teste confere o
/// guia de voz (RN-944) em todas. Sem exclamação, sem julgamento: o extrato
/// é um relato, e a Juju só confere com a pessoa.
abstract final class StatementWords {
  /// "Lendo a página 3 de 7…"
  static String reading(int page, int pages) =>
      pages <= 1 ? 'Lendo o extrato…' : 'Lendo a página $page de $pages…';

  /// O resumo que abre a conversa (RN-1112).
  static String summary(StatementDigest digest) {
    final lines = digest.lines;
    if (lines.isEmpty) return 'Não achei movimentações neste extrato.';
    final read = _count(lines.length, 'movimentação', 'movimentações');
    return [
      'Li $read ${_span(lines)}.',
      ?_counted(digest),
      ?_leftOut(digest),
      ?_already(digest.alreadyThere.length),
      ?_doubts(digest.questions.length),
      ?_installmentsNote(digest.installments.length),
    ].join(' ');
  }

  static String? _installmentsNote(int count) => count == 0
      ? null
      : '${_count(count, 'parcela', 'parcelas')} de compras de outros meses: '
            'pergunto no fim.';

  /// A pergunta das parcelas (RN-1111): "8 parcelas de compras de outros
  /// meses, R$ 640,00 — lanço como gasto deste mês?"
  static String installments(StatementDigest digest) {
    final total = digest.installmentTotal;
    final count = digest.installments.length;
    return '${_count(count, 'parcela', 'parcelas')} de compras de outros '
        'meses, ${_tenders(total.cash, total.voucher)} — lanço como gasto '
        'deste mês?';
  }

  /// O que já estava no Cajui e ficou de fora (RN-1112).
  static String already(int count) =>
      '${_count(count, 'movimentação já estava', 'movimentações já estavam')} '
      'no Cajui e ${count == 1 ? 'ficou' : 'ficaram'} de fora. Confere?';

  /// A pergunta do cartão, quando há mais de um cadastrado (RN-1114).
  static const whichCard =
      'As compras no cartão deste extrato são de qual cartão?';

  static String? _already(int count) => count == 0
      ? null
      : '${_count(count, 'já estava', 'já estavam')} no Cajui.';

  static String? _doubts(int count) => count == 0
      ? null
      : '${_count(count, 'ficou', 'ficaram')} em dúvida: pergunto depois dos '
            'blocos.';

  /// "62 gastos, R$ 2.371,90; 2 entradas, R$ 3.120,00."
  static String? _counted(StatementDigest digest) {
    final spending = digest.spending;
    final income = digest.income;
    final parts = [
      ?_part(spending.count, 'gasto', 'gastos', (
        cash: spending.cash,
        voucher: spending.voucher,
      )),
      ?_part(digest.incomes.length, 'entrada', 'entradas', income),
    ];
    return parts.isEmpty ? null : '${_capital(parts.join('; '))}.';
  }

  static String? _part(
    int count,
    String one,
    String many,
    ({Money cash, Money voucher}) total,
  ) => count == 0
      ? null
      : '${_count(count, one, many)}, ${_tenders(total.cash, total.voucher)}';

  /// "4 pagamentos de fatura e 9 transferências entre suas contas não
  /// contam."
  static String? _leftOut(StatementDigest digest) {
    final cards = digest.countLeftOut(StatementDigest.isCardPayment);
    final moves = digest.countLeftOut(StatementDigest.isTransfer);
    final others = digest.leftOut.length - cards - moves;
    final parts = [
      if (cards > 0)
        _count(cards, 'pagamento de fatura', 'pagamentos de fatura'),
      if (moves > 0)
        _count(
          moves,
          'transferência entre contas',
          'transferências entre contas',
        ),
      if (others > 0) _count(others, 'outra', 'outras'),
    ];
    if (parts.isEmpty) return null;
    final total = cards + moves + others;
    return '${_capital(_and(parts))} ${total == 1 ? 'não conta' : 'não contam'}.';
  }

  /// "Mercado — 12 compras, R$ 1.240,00: Assaí, Atacadão, Pão de Açúcar e
  /// mais 9. Confere?" (RN-1113).
  static String block(
    StatementBlock block,
    String category,
    List<ResolvedLine> lines,
  ) {
    final names = <String>{
      for (final i in block.lines) lines[i].line.description,
    }.toList();
    final shown = names.take(3).toList();
    final rest = names.length - shown.length;
    final list = rest > 0 ? '${shown.join(', ')} e mais $rest' : _and(shown);
    final purchases = _count(block.lines.length, 'compra', 'compras');
    return '$category — $purchases, ${_tenders(block.cash, block.voucher)}: '
        '$list. Confere?';
  }

  /// O rótulo de uma linha na lista curta: "05/10 · Assaí".
  static String row(ResolvedLine line) =>
      '${_day(line.line.occurredOn)} · ${line.line.description}';

  /// O valor de uma linha na lista curta.
  static String amount(ResolvedLine line) => MoneyFormat.brl(line.line.amount);

  /// A pergunta sobre uma linha em dúvida (RN-1114).
  static String question(StatementQuestion question, ResolvedLine line) {
    final what =
        '${line.line.description}, ${MoneyFormat.brl(line.line.amount)}, '
        'em ${_day(line.line.occurredOn)}.';
    return switch (question) {
      KindQuestion() => '$what O que foi?',
      CategoryQuestion() => '$what Qual é a categoria?',
    };
  }

  /// A resposta de tipo, como aparece no botão.
  static String treatment(LineTreatment treatment) => switch (treatment) {
    LineTreatment.expense => 'É um gasto',
    LineTreatment.income => 'É dinheiro que entrou',
    LineTreatment.household => 'Alguém da casa',
    LineTreatment.ownAccount => 'Conta minha',
    LineTreatment.ignore => 'Não lançar',
  };

  /// "Pode lançar (58)" (RN-1115).
  static String launch(int count) => 'Pode lançar ($count)';

  /// Enquanto o arquivo abre, antes de se saber quantas páginas há.
  static const opening = 'Abrindo o extrato…';

  /// Enquanto o lote é gravado.
  static const saving = 'Lançando…';

  /// Tudo conferido: falta só lançar (RN-1115).
  static String ready(int count) => count == 0
      ? 'Conferido. Nada novo para lançar deste extrato.'
      : 'Tudo conferido: '
            '${_count(count, 'lançamento pronto', 'lançamentos prontos')} '
            'para entrar.';

  /// Depois de gravar (RN-1118). Os que o domínio recusou vêm à parte, com
  /// o texto do catálogo.
  static String done({
    required int recorded,
    int already = 0,
    int refused = 0,
  }) => [
    if (recorded > 0)
      'Lancei ${_count(recorded, 'lançamento', 'lançamentos')}.'
    else if (refused == 0)
      'Nada novo para lançar.',
    ?_stayedOut(already),
    ?_refused(refused),
    if (recorded > 0) 'Se algo não estiver certo, dá para desfazer tudo.',
  ].join(' ');

  static String? _stayedOut(int count) => switch (count) {
    0 => null,
    1 => '1 já estava no Cajui e não entrou de novo.',
    _ => '$count já estavam no Cajui e não entraram de novo.',
  };

  static String? _refused(int count) => count == 0
      ? null
      : '${_count(count, 'não entrou', 'não entraram')}: o motivo vem abaixo.';

  /// Depois de desfazer o lote (RN-1119).
  static String undone(int count) =>
      count == 1 ? 'Desfiz o lançamento.' : 'Desfiz os $count lançamentos.';

  /// As páginas que ficaram de fora ou foram lidas em parte (RN-1101 a
  /// RN-1103); `null` quando todas foram lidas inteiras.
  static String? pages({
    required int read,
    required int total,
    List<int> failed = const [],
    List<int> partial = const [],
  }) {
    final notes = [
      if (read < total) 'Li as páginas 1 a $read de $total.',
      ?_pagesNote(failed, 'não deu para ler', 'não deram para ler'),
      ?_pagesNote(partial, 'foi lida em parte', 'foram lidas em parte'),
    ];
    return notes.isEmpty ? null : notes.join(' ');
  }

  /// "A página 4 não deu para ler." ou "As páginas 4 e 6 não deram…".
  static String? _pagesNote(List<int> pages, String one, String many) {
    if (pages.isEmpty) return null;
    if (pages.length == 1) return 'A página ${pages.single} $one.';
    return 'As páginas ${_and([for (final p in pages) '$p'])} $many.';
  }

  /// "de 1 a 31 de outubro", "de 28 de setembro a 3 de outubro", "em 5 de
  /// outubro".
  static String _span(List<ResolvedLine> lines) {
    final days = lines.map((line) => line.line.occurredOn).toList()..sort();
    final (first, last) = (days.first, days.last);
    String full(LocalDate day) =>
        '${day.day} de ${CalendarWords.month(day.budgetMonth)}';
    if (first == last) return 'em ${full(first)}';
    if (first.budgetMonth == last.budgetMonth) {
      return 'de ${first.day} a ${full(last)}';
    }
    return 'de ${full(first)} a ${full(last)}';
  }

  /// "R$ 1.000,00" ou "R$ 1.000,00 em dinheiro e R$ 240,00 no vale": as
  /// moedas nunca se somam (RN-111).
  static String _tenders(Money cash, Money voucher) {
    if (voucher.isZero) return MoneyFormat.brl(cash);
    if (cash.isZero) return '${MoneyFormat.brl(voucher)} no vale';
    return '${MoneyFormat.brl(cash)} em dinheiro e '
        '${MoneyFormat.brl(voucher)} no vale';
  }

  static String _day(LocalDate day) =>
      '${day.day.toString().padLeft(2, '0')}/'
      '${day.month.toString().padLeft(2, '0')}';

  static String _count(int count, String one, String many) =>
      '$count ${count == 1 ? one : many}';

  static String _and(List<String> parts) => parts.length <= 1
      ? parts.join()
      : '${parts.sublist(0, parts.length - 1).join(', ')} e ${parts.last}';

  static String _capital(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}
