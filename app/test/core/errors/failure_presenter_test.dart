import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/core/errors/failure_presenter.dart';
import 'package:cajui/src/core/format/date_labels.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

const Money _ten = Money.fromCents(1000);
const Money _twenty = Money.fromCents(2000);

/// Uma amostra de cada recusa que o domínio sabe dar.
final List<Failure> _everyFailure = [
  const PaymentLinesMismatch(amount: _twenty, linesTotal: _ten),
  PurchaseDateInFuture(
    occurredOn: LocalDate(2026, 9, 21),
    today: LocalDate(2026, 9, 20),
  ),
  const NonPositiveAmount(Money.zero),
  const ReversalExceedsRemaining(remaining: _ten, requested: _twenty),
  const VoucherBalanceExceeded(balance: _ten, requested: _twenty),
  const CategoryNotVoucherEligible('Internet'),
  const InvalidCardDay(32),
  const CategoryRepresentsCard('Fatura do cartão'),
  const RangeMinAboveMax(min: _twenty, max: _ten),
  MonthNotOver(
    month: const BudgetMonth(2026, 9),
    closableFrom: LocalDate(2026, 10, 1),
  ),
  const AdjustmentBelowMinimum(
    categoryId: 'groceries',
    minimum: _twenty,
    result: _ten,
  ),
  const ReallocationExceedsSlack(slack: _ten, requested: _twenty),
  const PaidInstallmentsExceedTotal(total: 10, paid: 12),
];

/// O que a falha não carrega e só a tela sabe.
const Map<String, String> _names = {
  'forma': 'Pix',
  'categoria': 'Mercado',
  'origem': 'Lazer',
};

void main() {
  group('FailurePresenter', () {
    test('toda recusa do domínio vira texto sem nenhuma {chave} sobrando', () {
      for (final failure in _everyFailure) {
        final error = FailurePresenter.present(failure, names: _names);
        final all = [error.text.message, ...error.text.actions].join(' ');

        expect(all, isNot(contains('{')), reason: '${failure.runtimeType}');
      }
    });

    test('a amostra cobre os 13 códigos de regra do catálogo', () {
      final codes = {
        for (final failure in _everyFailure)
          FailurePresenter.present(failure, names: _names).code,
      };
      final ruleCodes = ErrorCode.values.where(
        (code) =>
            code.errorClass == ErrorClass.rule ||
            code.errorClass == ErrorClass.validation,
      );

      expect(codes, ruleCodes.toSet());
    });

    test('dinheiro sai no formato da casa, e o mês abre a frase', () {
      final voucher = FailurePresenter.present(
        const VoucherBalanceExceeded(balance: _ten, requested: _twenty),
      );
      final month = FailurePresenter.present(
        MonthNotOver(
          month: const BudgetMonth(2026, 9),
          closableFrom: LocalDate(2026, 10, 1),
        ),
      );

      expect(
        voucher.text.message,
        startsWith('O vale tem R\$${BrlFormatter.nbsp}10,00'),
      );
      expect(month.text.message, startsWith('Setembro de 2026 ainda não'));
      expect(month.text.message, contains('a partir de 1 de outubro'));
    });
  });

  group('DateLabels', () {
    final today = LocalDate(2026, 9, 20);

    test('perto é relativo; longe é por extenso e curto', () {
      expect(DateLabels.day(today, today: today), 'hoje');
      expect(DateLabels.day(today.addDays(-1), today: today), 'ontem');
      expect(
        DateLabels.day(LocalDate(2026, 9, 12), today: today),
        'sáb., 12 de set.',
      );
    });

    test('mês por extenso', () {
      expect(DateLabels.month(const BudgetMonth(2026, 3)), 'março de 2026');
    });
  });
}
