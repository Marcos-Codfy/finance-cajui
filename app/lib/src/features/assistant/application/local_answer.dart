import 'package:cajui/src/features/assistant/application/answer_source.dart';
import 'package:cajui/src/features/assistant/application/assistant_reply.dart';
import 'package:cajui/src/features/budget/application/month_overview.dart';
import 'package:cajui/src/features/insights/application/insights.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:domain/domain.dart';

/// A resposta que o próprio aparelho dá, sem servidor e sem IA (RN-960).
///
/// É a primeira camada da conversa. O domínio já calcula limite da semana,
/// sobra do mês, gasto por categoria, saldo do vale, reserva da fatura e o
/// que falta nas dívidas — e calcula **exato**. Mandar isso para um modelo de
/// linguagem seria pagar para que alguém redija, com risco de erro, uma conta
/// que já está pronta.
///
/// Devolve `null` quando a pergunta não cabe aqui ou quando falta o dado: aí
/// a pergunta segue para a IA, que é para onde ela sempre foi.
abstract final class LocalAnswer {
  /// A resposta local para [intent], ou `null`.
  static AssistantAnswered? of(
    QuestionIntent intent, {
    required Insights insights,
    required MonthOverview overview,
    required LedgerBook book,
  }) => switch (intent) {
    QuestionIntent.today => _from(insights.daily.lines),
    QuestionIntent.weekLimit => _week(insights, overview),
    QuestionIntent.monthClosing => _month(insights, overview),
    QuestionIntent.whereMoneyWent => _where(overview, book),
    QuestionIntent.voucherBalance => _voucher(overview),
    QuestionIntent.cardBill => _card(overview),
    QuestionIntent.debts => _debts(overview),
    QuestionIntent.unknown => null,
  };

  /// Junta as frases do resumo numa resposta só. As frases são do domínio e
  /// já passaram pelo guia de voz.
  static AssistantAnswered? _from(
    List<String> lines, {
    List<AnswerSource> sources = const [],
  }) {
    final text = lines.where((line) => line.isNotEmpty).join(' ');
    if (text.isEmpty) return null;
    return AssistantAnswered(text, sources: sources);
  }

  static AssistantAnswered? _week(Insights insights, MonthOverview overview) {
    final weekly = insights.weekly;
    if (weekly == null) return null;
    final week = overview.week;
    return _from(
      weekly.lines,
      sources: [
        _source('Resta nesta semana', week.remaining, overview, 'projection'),
        _source('Limite da semana', week.limit, overview, 'plan'),
        _source('Gasto na semana', week.spent, overview, 'fact'),
      ],
    );
  }

  static AssistantAnswered? _month(Insights insights, MonthOverview overview) {
    final monthly = insights.monthly;
    final indicators = overview.indicators;
    return _from(
      [...monthly.howItWent, ...monthly.whatComesNext],
      sources: [
        _source(
          'Sobra prevista',
          indicators.projectedResult,
          overview,
          'projection',
        ),
        _source('Sobra planejada', indicators.plannedResult, overview, 'plan'),
      ],
    );
  }

  /// Para onde foi o dinheiro: as categorias com gasto, da maior para a
  /// menor. Dinheiro e vale continuam separados — nunca se somam (RN-111).
  static AssistantAnswered? _where(MonthOverview overview, LedgerBook book) {
    final spent = book.spentIn(overview.plan.month);
    final totals =
        overview.indicators.spending.routineByCategory.entries
            .where((line) => line.value.isPositive)
            .toList()
          ..sort((a, b) => b.value.cents.compareTo(a.value.cents));
    if (totals.isEmpty) return null;
    final parts = [
      for (final line in totals.take(6))
        '${book.categoryOf(line.key).name}, ${MoneyFormat.brl(line.value)}',
    ];
    return AssistantAnswered(
      'Em ${CalendarWords.month(overview.plan.month)}, o gasto de rotina '
      'ficou assim: ${parts.join('; ')}. '
      'Em dinheiro, ${MoneyFormat.brl(spent.cash)}; '
      'no vale, ${MoneyFormat.brl(spent.mealVoucher)}.',
      sources: [
        for (final line in totals.take(6))
          _source(book.categoryOf(line.key).name, line.value, overview, 'fact'),
      ],
    );
  }

  static AssistantAnswered _voucher(MonthOverview overview) {
    final balance = overview.voucher.balance;
    return AssistantAnswered(
      'No vale alimentação restam ${MoneyFormat.brl(balance)}. '
      'Ele só paga alimentação, e não se soma ao dinheiro.',
      sources: [_source('Saldo do vale', balance, overview, 'fact')],
    );
  }

  static AssistantAnswered? _card(MonthOverview overview) {
    if (!overview.hasCards) return null;
    final reserve = overview.statementReserve;
    return AssistantAnswered(
      'A reserva da fatura está em ${MoneyFormat.brl(reserve)}. '
      'É o que já foi comprado no cartão e ainda vai sair da conta quando a '
      'fatura vencer — a compra já contou no mês em que foi feita.',
      sources: [_source('Reserva da fatura', reserve, overview, 'projection')],
    );
  }

  static AssistantAnswered? _debts(MonthOverview overview) {
    final due = overview.plan.debtInstallments;
    if (!due.isPositive) return null;
    return AssistantAnswered(
      'Em ${CalendarWords.month(overview.plan.month)}, as parcelas de dívida '
      'somam ${MoneyFormat.brl(due)}. Esse valor já está descontado da sobra '
      'prevista do mês.',
      sources: [_source('Parcelas do mês', due, overview, 'plan')],
    );
  }

  static AnswerSource _source(
    String label,
    Money amount,
    MonthOverview overview,
    String kind,
  ) => AnswerSource(
    label: label,
    cents: amount.cents,
    kind: kind,
    period: '${overview.plan.month}',
  );
}
