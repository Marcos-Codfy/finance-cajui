import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/budget/application/income_service.dart';
import 'package:cajui/src/features/export/application/export_month.dart';
import 'package:cajui/src/features/export/application/month_exporter.dart';
import 'package:cajui/src/features/home/application/home_view.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_exchange.dart';
import '../../support/test_scope.dart';
import '../../support/two_phones.dart';

const _september = BudgetMonth(2026, 9);

IncomeSource _salary(String id, int cents) => IncomeSource(
  id: id,
  name: id,
  tender: Tender.cash,
  expectedAmount: Money.fromCents(cents),
  expectedDay: 5,
);

/// A planilha da casa: o salário da Ana (R$ 1.800,00) e o do Beto
/// (R$ 1.500,00). Esperado no mês: R$ 3.300,00.
final _plan = BudgetDefined(
  BudgetPlan(
    salaries: [_salary('ana', 180000), _salary('beto', 150000)],
    definedAt: DateTime.utc(2026, 9),
  ),
);

/// O exportador de mentira: guarda o que recebeu.
final class _Exporter implements MonthExporter {
  final List<MonthExport> received = [];

  @override
  Future<void> export(MonthExport month) async => received.add(month);
}

/// O salário que o extrato leu como sendo o da Ana: R$ 2.000,00.
Future<void> _readSalary(ProviderContainer phone) => phone
    .read(incomeServiceProvider)
    .receiveIncome(
      tender: Tender.cash,
      amount: const Money.fromCents(200000),
      receivedOn: LocalDate(2026, 9, 5),
      salaryId: 'ana',
      id: 'salario-lido',
    );

Future<Money> _cashIncome(ProviderContainer phone) async =>
    BookFinances.of(await phone.read(ledgerProvider.future))
        .budgetFor(_september)
        .cashIncome;

void main() {
  group('RN-1120 · a entrada desfeita sai do mês', () {
    late ProviderContainer phone;
    late _Exporter exporter;

    setUp(() async {
      exporter = _Exporter();
      phone = ProviderContainer(
        overrides: [
          ...testOverrides(),
          monthExporterProvider.overrideWithValue(exporter),
        ],
      );
      addTearDown(phone.dispose);
      await phone.read(ledgerProvider.notifier).append(_plan);
      await _readSalary(phone);
    });

    test('desfazer o salário lido devolve a renda esperada do mês', () async {
      // 2.000 lidos da Ana mais 1.500 esperados do Beto.
      expect(await _cashIncome(phone), const Money.fromCents(350000));

      final undone = await phone
          .read(incomeServiceProvider)
          .cancelIncome('salario-lido');

      expect(undone, isTrue);
      expect(await _cashIncome(phone), const Money.fromCents(330000));
      final book = await phone.read(ledgerProvider.future);
      expect(book.receipts, isEmpty);
    });

    test(
      'a planilha exportada e o Início deixam de contar a entrada',
      () async {
        await phone.read(incomeServiceProvider).cancelIncome('salario-lido');

        await phone.read(exportMonthProvider).call(_september);
        final home = phone.read(homeViewProvider)!;

        expect(exporter.received.single.summary.first.amount.cents, 330000);
        expect(home.budget.cashIncome, const Money.fromCents(330000));
      },
    );

    test('desfazer duas vezes grava um fato só; e o que não existe, '
        'nenhum', () async {
      final service = phone.read(incomeServiceProvider);

      expect(await service.cancelIncome('salario-lido'), isTrue);
      expect(await service.cancelIncome('salario-lido'), isFalse);
      expect(await service.cancelIncome('nao-existe'), isFalse);

      final book = await phone.read(ledgerProvider.future);
      expect(book.facts.whereType<IncomeCancelled>(), hasLength(1));
    });

    test('a mesma chave não traz o desfeito de volta', () async {
      await phone.read(incomeServiceProvider).cancelIncome('salario-lido');

      await _readSalary(phone);

      expect(await _cashIncome(phone), const Money.fromCents(330000));
    });

    test('o crédito do vale desfeito sai do saldo', () async {
      final service = phone.read(incomeServiceProvider);
      await service.receiveIncome(
        tender: Tender.mealVoucher,
        amount: const Money.fromCents(50000),
        receivedOn: LocalDate(2026, 9, 1),
        id: 'vale-lido',
      );
      final before = (await phone.read(ledgerProvider.future)).voucher;

      await service.cancelIncome('vale-lido');

      final after = (await phone.read(ledgerProvider.future)).voucher;
      expect(before.balance, const Money.fromCents(50000));
      expect(after.balance, Money.zero);
    });
  });

  group('RN-1120 · desfeita num celular, desfeita no outro e no '
      'servidor', () {
    late FakeExchange server;
    late ProviderContainer a;
    late ProviderContainer b;

    setUp(() async {
      server = FakeExchange();
      a = TwoPhones.on(server);
      b = TwoPhones.on(server, today: testToday.addDays(1));
      await a.read(ledgerProvider.notifier).append(_plan);
      await _readSalary(a);
      await TwoPhones.sync(a);
      await TwoPhones.sync(b);
    });

    test('o outro celular volta à renda esperada', () async {
      expect(await _cashIncome(b), const Money.fromCents(350000));

      await a.read(incomeServiceProvider).cancelIncome('salario-lido');
      await TwoPhones.sync(a);
      final onB = await TwoPhones.sync(b);

      expect(onB.receipts, isEmpty);
      expect(await _cashIncome(b), const Money.fromCents(330000));
      expect(server.receipts, isEmpty);
      expect(server.facts.last.type, DeviceFact.incomeCancelled);
    });

    test(
      'o celular que ainda tinha o recebimento não o manda de volta',
      () async {
        await a.read(incomeServiceProvider).cancelIncome('salario-lido');
        await TwoPhones.sync(a);

        // B sobe antes de descer: o recebimento dele chega ao servidor depois
        // do desfazer, e não volta a valer.
        await TwoPhones.sync(b);
        final onA = await TwoPhones.sync(a);

        expect(server.receipts, isEmpty);
        expect(onA.receipts, isEmpty);
        expect(await _cashIncome(a), const Money.fromCents(330000));
      },
    );
  });
}
