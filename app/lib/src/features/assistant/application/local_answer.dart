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
    required String question,
    required Insights insights,
    required MonthOverview overview,
    required LedgerBook book,
  }) => switch (intent) {
    QuestionIntent.today => _from(insights.daily.lines),
    QuestionIntent.weekLimit => _week(insights, overview),
    QuestionIntent.monthClosing => _month(insights, overview),
    QuestionIntent.whereMoneyWent => _where(question, overview, book),
    QuestionIntent.voucherBalance => _voucher(overview),
    QuestionIntent.cardBill => _card(overview),
    QuestionIntent.debts => _debts(overview),
    QuestionIntent.dailyCost => _daily(overview),
    QuestionIntent.greeting => _greeting(insights),
    QuestionIntent.help => _help(),
    QuestionIntent.unknown => null,
  };

  /// Cumprimento não é pergunta — mas responder "olá" e parar seria um
  /// desperdício de toque. Vem junto a frase de hoje, que é o que a pessoa
  /// abriria o app para ver.
  static AssistantAnswered _greeting(Insights insights) => AssistantAnswered(
    '${AssistantIdentity.about} '
    '${insights.daily.lines.where((line) => line.isNotEmpty).join(' ')}',
  );

  static AssistantAnswered _help() => const AssistantAnswered(
    '${AssistantIdentity.about} Dá para me perguntar: quanto ainda dá para '
    'gastar nesta semana, como o mês está fechando, para onde foi o '
    'dinheiro, quanto gastei numa categoria, quanto resta no vale, quanto '
    'vem na fatura, quanto falta nas dívidas e quanto dá para gastar por '
    'dia. Essas eu respondo aqui mesmo, na hora e sem internet. O resto eu '
    'levo ao servidor.',
  );

  /// Quanto dá para gastar por dia, pelo plano. As duas moedas lado a lado,
  /// e nunca somadas (RN-111).
  static AssistantAnswered? _daily(MonthOverview overview) {
    final daily = overview.indicators.plannedDailyCost;
    if (!daily.cash.isPositive && !daily.mealVoucher.isPositive) return null;
    final real = overview.realizedDailyCost;
    return AssistantAnswered(
      'Pelo plano de ${CalendarWords.month(overview.plan.month)}, dá para '
      'gastar ${MoneyFormat.brl(daily.cash)} por dia em dinheiro'
      '${daily.mealVoucher.isPositive ? ', mais ${MoneyFormat.brl(daily.mealVoucher)} no vale' : ''}.'
      '${_soFar(real)}',
      sources: [
        _source('Custo por dia planejado', daily.cash, overview, 'plan'),
        if (real.cash.isPositive)
          _source('Custo por dia até aqui', real.cash, overview, 'fact'),
      ],
    );
  }

  /// O custo por dia que o mês vem tendo, ao lado do que ele previa
  /// (RN-651). Sai só quando já houve gasto: no dia 1º não há média, e uma
  /// frase dizendo "R$ 0,00 por dia" seria ruído.
  static String _soFar(TenderAmounts real) {
    if (!real.cash.isPositive) return '';
    return ' Até aqui, o mês vem custando ${MoneyFormat.brl(real.cash)} por '
        'dia em dinheiro'
        '${real.mealVoucher.isPositive ? ', mais ${MoneyFormat.brl(real.mealVoucher)} no vale' : ''}.';
  }

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
  static AssistantAnswered? _where(
    String question,
    MonthOverview overview,
    LedgerBook book,
  ) {
    final named = _categoryNamedIn(question, book);
    if (named != null) return _forCategory(named, overview, book);
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

  /// A categoria que a pergunta nomeia, se nomear alguma. Compara pelo nome
  /// que a pessoa vê na tela, sem acento e sem caixa.
  static Category? _categoryNamedIn(String question, LedgerBook book) {
    final text = QuestionRouter.normalize(question);
    for (final category in book.categories) {
      if (text.contains(QuestionRouter.normalize(category.name))) {
        return category;
      }
    }
    return null;
  }

  static AssistantAnswered _forCategory(
    Category category,
    MonthOverview overview,
    LedgerBook book,
  ) {
    final spent =
        overview.indicators.spending.routineByCategory[category.id] ??
        Money.zero;
    final month = CalendarWords.month(overview.plan.month);
    return AssistantAnswered(
      spent.isPositive
          ? 'Em $month, ${category.name} levou ${MoneyFormat.brl(spent)} '
                'de rotina.'
          : 'Em $month ainda não há gasto de rotina em ${category.name}.',
      sources: [_source(category.name, spent, overview, 'fact')],
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
