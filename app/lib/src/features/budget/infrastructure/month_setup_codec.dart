import 'package:cajui/src/features/budget/application/month_setup.dart';
import 'package:domain/domain.dart';

/// A ida e a volta entre o plano do mês e o que fica gravado no registro.
///
/// Dinheiro viaja em centavos inteiros, como em todo o resto (RN-101).
abstract final class MonthSetupCodec {
  /// O que gravar para [setup].
  static Map<String, Object?> encode(MonthSetup setup) => {
    'cashIncomeCents': setup.cashIncome.cents,
    'debtInstallmentsCents': setup.debtInstallments.cents,
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

  static Money _money(Object? cents) => Money.fromCents(cents as int? ?? 0);

  static Iterable<Map<String, Object?>> _maps(Object? list) =>
      (list as List<Object?>? ?? const []).whereType<Map<String, Object?>>();
}
