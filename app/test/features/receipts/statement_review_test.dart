import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/receipts/application/read_outcome.dart';
import 'package:cajui/src/features/receipts/application/shared_item.dart';
import 'package:cajui/src/features/receipts/presentation/capture_state.dart';
import 'package:cajui/src/features/receipts/presentation/capture_view_model.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_inbox.dart';
import '../../support/fake_reader.dart';
import '../../support/pick_document.dart';
import '../../support/test_scope.dart';

StatementLine _line(
  String description,
  int cents, {
  int day = 3,
  StatementLineKind kind = StatementLineKind.expense,
  PaymentMethodKind? paidBy,
  bool doubtful = false,
}) => StatementLine(
  occurredOn: LocalDate(2026, 9, day),
  description: description,
  amount: Money.fromCents(cents),
  kind: kind,
  paymentKind: paidBy,
  doubtful: doubtful,
);

Future<LedgerBook Function()> _statement(
  WidgetTester tester,
  List<StatementLine> lines,
) async {
  final (_, book) = await pickDocument(
    tester,
    proposalOf(DocumentKind.statement, lines: lines),
  );
  return book;
}

void main() {
  group('RN-707 · as correções da revisão do extrato', () {
    testWidgets('RN-111 · linha sem forma de pagamento sai da conta, nunca do '
        'vale nem do cartão', (tester) async {
      final book = await _statement(tester, [
        _line('Padaria Central', 1500),
        _line('Farmácia', 3000, day: 4),
      ]);

      expect(find.textContaining('Débito'), findsWidgets);
      await tapAndSettle(tester, find.text('Lançar 2 movimentações'));

      final kinds = [
        for (final entry in book().entries)
          for (final line in entry.paymentLines) line.kind,
      ];
      expect(kinds, everyElement(PaymentMethodKind.debit));
    });

    testWidgets('RN-758 · o salário do extrato é a renda do plano, e não '
        'entra por cima dela', (tester) async {
      final book = await _statement(tester, [
        _line('Salário', 320000, day: 5, kind: StatementLineKind.income),
        _line('Padaria Central', 1500),
      ]);

      expect(find.textContaining('renda do mês'), findsOneWidget);
      await tapAndSettle(tester, find.text('Salário'));
      await tapAndSettle(tester, find.text('Lançar 2 movimentações'));

      expect(book().receipts.last.sourceId, LedgerBook.cashIncomeSourceId);
      expect(
        book().cashIncomeIn(const BudgetMonth(2026, 9)),
        const Money.fromCents(320000),
      );
    });

    testWidgets('linha em dúvida aparece, dá para marcar, mas não vem marcada '
        '(RN-757)', (tester) async {
      await _statement(tester, [
        _line(
          'Nu Pagamentos',
          150000,
          kind: StatementLineKind.cardPayment,
          doubtful: true,
        ),
        _line('Padaria Central', 1500),
      ]);

      expect(find.textContaining('Parece pagamento de fatura'), findsWidgets);
      expect(find.text('Lançar 1 movimentação'), findsOneWidget);
    });

    testWidgets('o que o domínio recusa não some: a tela fica, com o motivo', (
      tester,
    ) async {
      final book = await _statement(tester, [
        _line('Padaria Central', 1500),
        _line(
          'Supermercado',
          100000,
          day: 4,
          paidBy: PaymentMethodKind.mealVoucher,
        ),
      ]);
      final entries = book().entries.length;

      await tapAndSettle(tester, find.text('Lançar 2 movimentações'));

      expect(book().entries, hasLength(entries + 1));
      expect(find.textContaining('não entrou'), findsOneWidget);
      expect(find.textContaining('Lançada'), findsOneWidget);
      expect(find.text('Pronto'), findsOneWidget);
    });

    testWidgets('RN-758 · Pix recebido que parece o salário já vem como '
        'renda do mês', (tester) async {
      final (_, book) = await pickDocument(
        tester,
        proposalOf(
          DocumentKind.incomeReceipt,
          amount: const Money.fromCents(320000),
        ).copyWith(
          occurredOn: ProposedField.resolved(
            LocalDate(2026, 9, 5),
            source: FieldSource.ai,
          ),
        ),
      );

      await tapAndSettle(tester, find.text('Registrar entrada'));

      expect(book().receipts.last.sourceId, LedgerBook.cashIncomeSourceId);
    });
  });

  testWidgets('RN-756 · pagamento de fatura leva à fatura do cartão, onde o '
      'domínio sabe qual fatura está aberta', (tester) async {
    final card = CreditCard.create(
      id: 'card-1',
      name: 'Cartão da casa',
      closingDay: 25,
      dueDay: 5,
    ).valueOrNull!;
    final (inbox, book) = await pickDocument(
      tester,
      proposalOf(
        DocumentKind.statementPayment,
        amount: const Money.fromCents(124000),
      ),
      events: [CardDefined(id: 'card-fact-1', card: card)],
    );
    final entries = book().entries.length;

    expect(find.textContaining('1.240,00'), findsOneWidget);
    await tapAndSettle(
      tester,
      find.text('Ver a fatura e registrar o pagamento'),
    );
    expect(find.text('Cartão da casa'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator).last).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tapAndSettle(tester, find.text('Pronto'));

    expect(book().entries, hasLength(entries));
    expect(inbox.discarded, isEmpty);
  });

  test('dois toques em "Descartar" não levam junto o comprovante seguinte da '
      'fila', () async {
    final inbox = FakeInbox();
    final container = ProviderContainer(
      overrides: testOverrides(
        inbox: inbox,
        reader: FakeReader(const {
          '/inbox/a': ReadText('PADARIA CENTRAL\nTOTAL R\$ 8,50\n12/09/2026'),
          '/inbox/b': ReadText('FARMACIA BOA\nTOTAL R\$ 30,00\n12/09/2026'),
        }),
      ),
    );
    addTearDown(container.dispose);
    final vm = container.read(captureProvider.notifier);
    inbox.share(const [
      SharedFile(id: 'a', path: '/inbox/a', isPdf: false),
      SharedFile(id: 'b', path: '/inbox/b', isPdf: false),
    ]);
    await pumpEventQueue();
    final first = (container.read(captureProvider) as CaptureReady).capture;

    await Future.wait([vm.discard(first), vm.discard(first)]);

    final now = container.read(captureProvider);
    expect(now, isA<CaptureReady>());
    expect((now as CaptureReady).capture.source.id, 'b');
  });
}
