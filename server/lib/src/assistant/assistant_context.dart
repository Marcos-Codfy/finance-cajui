import 'package:domain/domain.dart';
import 'package:meta/meta.dart';
import 'package:server/src/assistant/context_number.dart';
import 'package:server/src/assistant/context_number_kind.dart';

/// O **contexto do assistente** (RN-910 a RN-918): o que o servidor conta à
/// IA sobre o mês — e nada além disso.
///
/// A menor unidade é **categoria no mês** (RN-912): nenhum lançamento,
/// descrição ou nome de estabelecimento entra aqui, então um mês com 140
/// lançamentos gera contexto do mesmo tamanho que um com 14. As duas moedas
/// ficam em números separados, e não existe número que as some (RN-917).
/// Cada número carrega a sua natureza e o período (RN-918).
///
/// É montado pelo servidor, com as funções do domínio (RN-915): o app nunca
/// manda número para o chat.
@immutable
final class AssistantContext {
  /// Monta o contexto do mês de [today] a partir dos lançamentos [entries]
  /// e dos números da planilha [sheet] (`SheetNumbers`).
  factory build({
    required LocalDate today,
    required Iterable<Entry> entries,
    required Map<String, Category> categories,
    Iterable<Reversal> reversals = const [],
    Iterable<ContextNumber> sheet = const [],
    TenderAmounts received = TenderAmounts.zero,
  }) {
    final month = today.budgetMonth;
    return AssistantContext._(
      today: today,
      month: month,
      numbers: _numbered([
        for (final (label, amounts) in _spent(
          month,
          entries,
          categories,
          reversals,
        ))
          ..._byTender(label, month, amounts),
        ...sheet,
        ..._byTender('O que entrou de fato', month, received),
      ]),
    );
  }

  const new _({
    required this.today,
    required this.month,
    required this.numbers,
  });

  /// A versão do esquema. Campo desconhecido reprova o teste de esquema.
  /// Subiu para 2 com os números da planilha (ADR-023), no lugar do plano
  /// antigo e do saldo do vale da operadora.
  static const schema = 2;

  /// O dia de hoje, no fuso de negócio.
  final LocalDate today;

  /// O mês aberto.
  final BudgetMonth month;

  /// Os números do contexto, cada um com origem, natureza e período.
  final List<ContextNumber> numbers;

  /// O gasto do mês, por categoria e no total (RN-912).
  static List<(String, TenderAmounts)> _spent(
    BudgetMonth month,
    Iterable<Entry> entries,
    Map<String, Category> categories,
    Iterable<Reversal> reversals,
  ) {
    final byCategory = <String, TenderAmounts>{};
    for (final entry in entries) {
      final known = byCategory[entry.categoryId] ?? TenderAmounts.zero;
      byCategory[entry.categoryId] = known + entry.spentIn(month);
    }
    _subtract(byCategory, month, entries, reversals);
    return [
      for (final MapEntry(key: id, value: spent) in byCategory.entries)
        // Nome de categoria é texto do usuário: passa pelo mascaramento
        // antes de sair (RN-919).
        ('Gasto em ${PiiRedactor.redact(categories[id]?.name ?? id)}', spent),
      (
        'Gasto do mês',
        byCategory.values.fold(TenderAmounts.zero, (a, b) => a + b),
      ),
    ];
  }

  /// O estorno reduz o gasto da categoria **no mês em que o dinheiro
  /// voltou** (RN-209), e pela moeda em que voltou (RN-211). Sem isto o
  /// servidor contava a compra devolvida inteira, e o assistente respondia
  /// um número que o aparelho já sabia errado.
  static void _subtract(
    Map<String, TenderAmounts> byCategory,
    BudgetMonth month,
    Iterable<Entry> entries,
    Iterable<Reversal> reversals,
  ) {
    final categoryOf = {
      for (final entry in entries) entry.id: entry.categoryId,
    };
    for (final reversal in reversals) {
      if (!month.contains(reversal.occurredOn)) continue;
      final category = categoryOf[reversal.entryId];
      if (category == null) continue;
      final back = TenderAmounts.single(
        reversal.line.kind.tender,
        reversal.line.amount,
      );
      byCategory[category] =
          (byCategory[category] ?? TenderAmounts.zero) - back;
    }
  }

  /// Um número por moeda, e só das moedas com gasto: o contexto não tem campo
  /// de total que some dinheiro e vale.
  static Iterable<ContextNumber> _byTender(
    String label,
    BudgetMonth month,
    TenderAmounts amounts, {
    ContextNumberKind kind = ContextNumberKind.fact,
  }) sync* {
    for (final tender in Tender.values) {
      final amount = amounts.of(tender);
      if (amount.isZero) continue;
      final currency = tender == Tender.cash ? 'em dinheiro' : 'no vale';
      yield ContextNumber(
        id: '',
        label: '$label, $currency',
        kind: kind,
        period: '$month',
        amount: amount,
      );
    }
  }

  /// Identificadores curtos e em sequência (`n1`, `n2`…): é por eles que a
  /// IA diz de onde tirou cada número.
  static List<ContextNumber> _numbered(List<ContextNumber> numbers) => [
    for (final (index, number) in numbers.indexed)
      ContextNumber(
        id: 'n${index + 1}',
        label: number.label,
        kind: number.kind,
        period: number.period,
        amount: number.amount,
      ),
  ];

  /// O número de identificador [id], ou `null`.
  ContextNumber? numberById(String id) {
    for (final number in numbers) {
      if (number.id == id) return number;
    }
    return null;
  }

  /// O contexto como vai para a IA.
  Map<String, Object?> toJson() => {
    'schema': schema,
    'today': '$today',
    'openMonth': '$month',
    'numbers': [for (final number in numbers) number.toJson()],
  };
}
