import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

/// A ida e a volta do plano do mês: entre o registro do aparelho, o corpo da
/// rota `/v1/plan` e o `MonthSetup` do domínio.
///
/// Dinheiro viaja em centavos inteiros, como em todo o resto (RN-101). Era um
/// codec só do app; virou contrato quando o plano passou a subir para o
/// servidor, para que os dois lados leiam o mesmo formato (BL-049).
abstract final class MonthSetupCodec {
  /// O que gravar para [setup].
  static Map<String, Object?> encode(MonthSetup setup) => {
    'cashIncomeCents': setup.cashIncome.cents,
    'debtInstallmentsCents': setup.debtInstallments.cents,
    // Só viaja quando existe: registro antigo não tem carimbo, e continua
    // abrindo igual.
    'definedAt': ?setup.definedAt?.toIso8601String(),
    'fixed': [
      for (final fixed in setup.fixedExpenses)
        {
          'id': fixed.id,
          'name': fixed.name,
          'amountCents': fixed.amount.cents,
          'dueDay': fixed.dueDay,
          'categoryId': fixed.categoryId,
          'paymentMethodId': fixed.paymentMethodId,
        },
    ],
    'variables': [
      for (final budget in setup.variableBudgets)
        {
          'categoryId': budget.categoryId,
          'minCents': budget.range.min.cents,
          'maxCents': budget.range.max.cents,
          'voucherEligible': budget.voucherEligible,
        },
    ],
  };

  /// O plano gravado em [payload].
  static MonthSetup decode(Map<String, Object?> payload) => MonthSetup(
    cashIncome: _money(payload['cashIncomeCents']),
    debtInstallments: _money(payload['debtInstallmentsCents']),
    definedAt: _instant(payload['definedAt']),
    fixedExpenses: [
      for (final raw in _maps(payload['fixed']))
        FixedExpense(
          id: raw['id']! as String,
          name: raw['name']! as String,
          amount: _money(raw['amountCents']),
          dueDay: raw['dueDay']! as int,
          categoryId: raw['categoryId']! as String,
          paymentMethodId: raw['paymentMethodId']! as String,
        ),
    ],
    variableBudgets: [
      for (final raw in _maps(payload['variables']))
        // A faixa já foi aceita pelo domínio quando foi gravada.
        if (AmountRange.create(
              min: _money(raw['minCents']),
              max: _money(raw['maxCents']),
            ).valueOrNull
            case final range?)
          VariableBudget(
            categoryId: raw['categoryId']! as String,
            range: range,
            voucherEligible: raw['voucherEligible'] as bool? ?? false,
          ),
    ],
  );

  /// O plano vindo **de fora**, campo a campo (T-05).
  ///
  /// [decode] relê o que este aparelho mesmo gravou, e por isso é tolerante:
  /// um registro antigo não pode derrubar o app na abertura. Aqui é o
  /// contrário — o corpo chegou pela rede, e campo faltando, campo a mais,
  /// tipo errado ou valor negativo viram `E-REQ-01`.
  static MonthSetup read(Object? json) {
    final body = JsonReader(
      json,
      allowed: const {
        'cashIncomeCents',
        'debtInstallmentsCents',
        'fixed',
        'variables',
        'definedAt',
      },
    );
    return MonthSetup(
      definedAt: body.optionalInstant('definedAt'),
      cashIncome: _positive(body.integer('cashIncomeCents'), 'cashIncomeCents'),
      debtInstallments: _positive(
        body.integer('debtInstallmentsCents'),
        'debtInstallmentsCents',
      ),
      fixedExpenses: [
        for (final raw in body.optionalList('fixed')) _readFixed(raw),
      ],
      variableBudgets: [
        for (final raw in body.optionalList('variables')) _readBudget(raw),
      ],
    );
  }

  static FixedExpense _readFixed(Object? json) {
    final raw = JsonReader(
      json,
      allowed: const {
        'id',
        'name',
        'amountCents',
        'dueDay',
        'categoryId',
        'paymentMethodId',
      },
    );
    final dueDay = raw.integer('dueDay');
    if (dueDay < 1 || dueDay > 31) {
      throw const FormatException('campo "dueDay" fora do mês');
    }
    return FixedExpense(
      id: raw.string('id', maxLength: 64),
      name: raw.string('name', maxLength: 40),
      amount: _positive(raw.integer('amountCents'), 'amountCents'),
      dueDay: dueDay,
      categoryId: raw.string('categoryId', maxLength: 64),
      paymentMethodId: raw.string('paymentMethodId', maxLength: 64),
    );
  }

  static VariableBudget _readBudget(Object? json) {
    final raw = JsonReader(
      json,
      allowed: const {'categoryId', 'minCents', 'maxCents', 'voucherEligible'},
    );
    // Quem decide se a faixa fecha é o domínio, não a rota.
    final range = AmountRange.create(
      min: _positive(raw.integer('minCents'), 'minCents'),
      max: _positive(raw.integer('maxCents'), 'maxCents'),
    ).valueOrNull;
    if (range == null) {
      throw const FormatException('faixa com mínimo maior que o máximo');
    }
    return VariableBudget(
      categoryId: raw.string('categoryId', maxLength: 64),
      range: range,
      voucherEligible: raw.boolean('voucherEligible', orElse: false),
    );
  }

  /// Dinheiro que vem de fora nunca é negativo: renda, conta e faixa são
  /// quantias, e o sinal é do domínio, não do corpo do pedido.
  static Money _positive(int cents, String field) {
    if (cents < 0) throw FormatException('campo "$field" negativo');
    return Money.fromCents(cents);
  }

  static Money _money(Object? cents) => Money.fromCents(cents as int? ?? 0);

  /// O carimbo, quando há um e quando dá para ler. Carimbo ilegível vale
  /// como nenhum: o plano continua abrindo, só perde a vez na disputa.
  static DateTime? _instant(Object? raw) =>
      raw is String ? DateTime.tryParse(raw)?.toUtc() : null;

  static Iterable<Map<String, Object?>> _maps(Object? list) =>
      (list as List<Object?>? ?? const []).whereType<Map<String, Object?>>();
}
