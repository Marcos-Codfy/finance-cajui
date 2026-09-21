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
  /// Monta o contexto do mês de [today] a partir dos lançamentos [entries].
  factory build({
    required LocalDate today,
    required Iterable<Entry> entries,
    required Map<String, Category> categories,
  }) {
    final month = today.budgetMonth;
    final byCategory = <String, TenderAmounts>{};
    for (final entry in entries) {
      final known = byCategory[entry.categoryId] ?? TenderAmounts.zero;
      byCategory[entry.categoryId] = known + entry.spentIn(month);
    }
    final total = byCategory.values.fold(TenderAmounts.zero, (a, b) => a + b);
    final labelled = [
      for (final MapEntry(key: id, value: spent) in byCategory.entries)
        // Nome de categoria é texto do usuário: passa pelo mascaramento
        // antes de sair (RN-919).
        ('Gasto em ${PiiRedactor.redact(categories[id]?.name ?? id)}', spent),
      ('Gasto do mês', total),
    ];
    return AssistantContext._(
      today: today,
      month: month,
      numbers: _numbered([
        for (final (label, amounts) in labelled)
          ..._byTender(label, month, amounts),
      ]),
    );
  }

  const new _({
    required this.today,
    required this.month,
    required this.numbers,
  });

  /// A versão do esquema. Campo desconhecido reprova o teste de esquema.
  static const schema = 1;

  /// O dia de hoje, no fuso de negócio.
  final LocalDate today;

  /// O mês aberto.
  final BudgetMonth month;

  /// Os números do contexto, cada um com origem, natureza e período.
  final List<ContextNumber> numbers;

  /// Um número por moeda, e só das moedas com gasto: o contexto não tem campo
  /// de total que some dinheiro e vale.
  static Iterable<ContextNumber> _byTender(
    String label,
    BudgetMonth month,
    TenderAmounts amounts,
  ) sync* {
    for (final tender in Tender.values) {
      final amount = amounts.of(tender);
      if (amount.isZero) continue;
      final currency = tender == Tender.cash ? 'em dinheiro' : 'no vale';
      yield ContextNumber(
        id: '',
        label: '$label, $currency',
        kind: ContextNumberKind.fact,
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
