import 'package:api_contract/src/json_reader.dart';
import 'package:domain/domain.dart';

/// A ida e a volta do plano da planilha (ADR-023): salários, vale, dízimo e
/// "Minhas contas".
///
/// Viaja como fato do aparelho (`budget.defined`), como a dívida e a fatura
/// paga: o servidor guarda e devolve para o outro celular, e o mais novo pelo
/// `definedAt` vale. [decode] relê o que o próprio aparelho gravou, e por
/// isso é tolerante; [read] lê o que chegou pela rede, campo a campo.
abstract final class BudgetPlanCodec {
  /// O maior nome de uma linha ou de um salário. A tela usa o mesmo teto: o
  /// que passa dele seria recusado aqui, e a recusa prendia a subida.
  static const int maxName = 40;

  /// A maior observação de uma linha.
  static const int maxNote = 80;

  /// O que gravar para [plan].
  static Map<String, Object?> encode(BudgetPlan plan) => {
    'definedAt': ?plan.definedAt?.toIso8601String(),
    'salaries': [
      for (final salary in plan.salaries)
        {
          'id': salary.id,
          'name': salary.name,
          'amountCents': salary.expectedAmount.cents,
          'payDay': salary.expectedDay,
        },
    ],
    'voucherCents': plan.voucher.cents,
    'titheBasisPoints': plan.titheBasisPoints,
    'lines': [for (final line in plan.lines) _encodeLine(line)],
    if (!plan.legacyDebtInstallments.isZero)
      'legacyDebtInstallmentsCents': plan.legacyDebtInstallments.cents,
  };

  static Map<String, Object?> _encodeLine(BudgetLine line) => {
    'id': line.id,
    'name': line.name,
    'amountCents': line.amount.cents,
    'group': line.group.name,
    'categoryId': line.categoryId,
    'paymentMethodId': ?line.paymentMethodId,
    'note': ?line.note,
    'dueDay': ?line.dueDay,
  };

  /// O plano gravado em [payload]. Linha que não se lê fica de fora sem
  /// levar as outras junto.
  static BudgetPlan decode(Map<String, Object?> payload) => BudgetPlan(
    definedAt: JsonReader.instantOf(payload['definedAt']),
    salaries: [
      for (final raw in _maps(payload['salaries']))
        _salary(
          id: raw['id']! as String,
          name: raw['name']! as String,
          cents: raw['amountCents']! as int,
          payDay: raw['payDay'] as int? ?? 5,
        ),
    ],
    voucher: Money.fromCents(payload['voucherCents'] as int? ?? 0),
    titheBasisPoints: payload['titheBasisPoints'] as int? ?? 0,
    lines: [for (final raw in _maps(payload['lines'])) ?_decodeLine(raw)],
    legacyDebtInstallments: Money.fromCents(
      payload['legacyDebtInstallmentsCents'] as int? ?? 0,
    ),
  );

  static BudgetLine? _decodeLine(Map<String, Object?> raw) {
    final group = LineGroup.values.asNameMap()[raw['group']];
    if (group == null) return null;
    return BudgetLine.create(
      id: raw['id']! as String,
      name: raw['name']! as String,
      amount: Money.fromCents(raw['amountCents']! as int),
      group: group,
      categoryId: raw['categoryId']! as String,
      paymentMethodId: raw['paymentMethodId'] as String?,
      note: raw['note'] as String?,
      dueDay: raw['dueDay'] as int?,
    ).valueOrNull;
  }

  static IncomeSource _salary({
    required String id,
    required String name,
    required int cents,
    required int payDay,
  }) => IncomeSource(
    id: id,
    name: name,
    tender: Tender.cash,
    expectedAmount: Money.fromCents(cents),
    expectedDay: payDay,
  );

  /// O plano vindo **de fora**. Campo faltando, a mais, tipo errado, valor
  /// negativo, dia fora do mês ou grupo que não existe — inclusive parcela de
  /// dívida, que nunca é linha — viram `E-REQ-01`.
  static BudgetPlan read(Object? json) {
    final body = JsonReader(
      json,
      allowed: const {
        'definedAt',
        'salaries',
        'voucherCents',
        'titheBasisPoints',
        'lines',
        'legacyDebtInstallmentsCents',
      },
    );
    return BudgetPlan(
      definedAt: body.optionalInstant('definedAt'),
      salaries: [
        for (final raw in body.optionalList('salaries', maxItems: 10))
          _readSalary(raw),
      ],
      voucher: _cents(body.integer('voucherCents'), 'voucherCents'),
      titheBasisPoints: _tithe(body.integer('titheBasisPoints')),
      lines: [
        for (final raw in body.optionalList('lines', maxItems: 80))
          _readLine(raw),
      ],
      legacyDebtInstallments: _cents(
        body.optionalInteger('legacyDebtInstallmentsCents') ?? 0,
        'legacyDebtInstallmentsCents',
      ),
    );
  }

  /// Dízimo é de zero a 100% da renda.
  static int _tithe(int basisPoints) {
    if (basisPoints < 0 || basisPoints > 10000) {
      throw const FormatException('campo "titheBasisPoints" fora do intervalo');
    }
    return basisPoints;
  }

  static IncomeSource _readSalary(Object? json) {
    final raw = JsonReader(
      json,
      allowed: const {'id', 'name', 'amountCents', 'payDay'},
    );
    return _salary(
      id: raw.string('id', maxLength: 64),
      name: raw.string('name', maxLength: maxName),
      cents: _cents(raw.integer('amountCents'), 'amountCents').cents,
      payDay: _day(raw.integer('payDay')),
    );
  }

  static BudgetLine _readLine(Object? json) {
    final raw = JsonReader(
      json,
      allowed: const {
        'id',
        'name',
        'amountCents',
        'group',
        'categoryId',
        'paymentMethodId',
        'note',
        'dueDay',
      },
    );
    final group = LineGroup.values.asNameMap()[raw.string('group')];
    if (group == null) throw const FormatException('campo "group"');
    final dueDay = raw.optionalInteger('dueDay');
    return BudgetLine.create(
      id: raw.string('id', maxLength: 64),
      name: raw.string('name', maxLength: maxName),
      amount: _cents(raw.integer('amountCents'), 'amountCents'),
      group: group,
      categoryId: raw.string('categoryId', maxLength: 64),
      paymentMethodId: raw.optionalString('paymentMethodId', maxLength: 64),
      note: raw.optionalString('note', maxLength: maxNote),
      dueDay: dueDay == null ? null : _day(dueDay),
    ).valueOrNull!;
  }

  static Money _cents(int cents, String field) {
    if (cents < 0) throw FormatException('campo "$field" negativo');
    return Money.fromCents(cents);
  }

  static int _day(int day) {
    if (day < 1 || day > 31) throw const FormatException('dia fora do mês');
    return day;
  }

  static Iterable<Map<String, Object?>> _maps(Object? list) => [
    for (final item in list is List ? list : const [])
      if (item is Map) item.cast<String, Object?>(),
  ];
}
