import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/receipts/application/capture_route.dart';
import 'package:cajui/src/features/receipts/application/read_outcome.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:cajui/src/features/receipts/application/shared_item.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_inbox.dart';
import '../../support/fake_reader.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await _settle(tester);
}

/// O que a leitura teria entendido do documento.
final class _Reads implements ReceiptClassifier {
  const new(this.proposal);

  final EntryProposal proposal;

  @override
  Future<EntryProposal> classify(ClassificationRequest request) async =>
      proposal;
}

EntryProposal _proposal(
  DocumentKind kind, {
  List<StatementLine> lines = const [],
  Money? amount,
}) => EntryProposal(
  documentKind: ProposedField.resolved(kind, source: FieldSource.ai),
  amount: amount == null
      ? const ProposedField.unread()
      : ProposedField.resolved(amount, source: FieldSource.ai),
  occurredOn: ProposedField.resolved(
    LocalDate(2026, 9, 12),
    source: FieldSource.ai,
  ),
  category: const ProposedField.unread(),
  paymentKind: const ProposedField.unread(),
  lines: lines,
);

final _statement = [
  StatementLine(
    occurredOn: LocalDate(2026, 9, 3),
    description: 'Padaria Central',
    amount: const Money.fromCents(1500),
  ),
  StatementLine(
    occurredOn: LocalDate(2026, 9, 5),
    description: 'Salário',
    amount: const Money.fromCents(320000),
    kind: StatementLineKind.income,
  ),
  StatementLine(
    occurredOn: LocalDate(2026, 9, 10),
    description: 'Fatura do cartão',
    amount: const Money.fromCents(150000),
    kind: StatementLineKind.cardPayment,
  ),
];

Widget _app(FakeInbox inbox, EntryProposal proposal) => ProviderScope(
  overrides: [
    ...testOverrides(
      journal: MemoryLedgerJournal(samplePlanEvents),
      inbox: inbox,
      reader: FakeReader(const {
        '/inbox/doc': ReadText('documento lido no aparelho'),
      }),
    ),
    receiptClassifierProvider.overrideWithValue(_Reads(proposal)),
  ],
  child: const CajuiApp(),
);

/// Abre o app, escolhe um documento da galeria e devolve com o que conferir
/// o livro depois.
Future<(FakeInbox, LedgerBook Function())> _pick(
  WidgetTester tester,
  EntryProposal proposal,
) async {
  tester.view.physicalSize = const Size(390, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final inbox = FakeInbox();
  await tester.pumpWidget(_app(inbox, proposal));
  await tester.pump();
  await _tap(tester, find.bySemanticsLabel('Lançamentos'));
  inbox.picked = const [
    SharedFile(id: 'doc', path: '/inbox/doc', isPdf: false),
  ];
  await _tap(tester, find.text('Da galeria'));
  final container = ProviderScope.containerOf(
    tester.element(find.byType(CajuiApp)),
  );
  return (inbox, () => container.read(ledgerProvider).value!);
}

void main() {
  group('para onde vai o documento lido', () {
    test('tipo em dúvida é compra, e "extrato" sem linhas também', () {
      const doubt = EntryProposal(
        documentKind: ProposedField.undecided([
          DocumentKind.purchase,
          DocumentKind.statementPayment,
        ], source: FieldSource.ai),
        amount: ProposedField.unread(),
        occurredOn: ProposedField.unread(),
        category: ProposedField.unread(),
        paymentKind: ProposedField.unread(),
      );

      expect(CaptureRoute.of(doubt), CaptureRoute.expense);
      expect(
        CaptureRoute.of(_proposal(DocumentKind.statement)),
        CaptureRoute.expense,
      );
      expect(
        CaptureRoute.of(_proposal(DocumentKind.ownTransfer)),
        CaptureRoute.notAnExpense,
      );
    });

    testWidgets('RN-707 · extrato: as despesas novas vêm marcadas, e só elas '
        'viram lançamento', (tester) async {
      final (_, book) = await _pick(
        tester,
        _proposal(DocumentKind.statement, lines: _statement),
      );
      final receipts = book().receipts.length;

      expect(find.textContaining('não é despesa'), findsOneWidget);
      await _tap(tester, find.text('Lançar 1 movimentação'));

      final descriptions = book().entries.map((entry) => entry.description);
      expect(descriptions, contains('Padaria Central'));
      expect(descriptions, isNot(contains('Fatura do cartão')));
      expect(book().receipts, hasLength(receipts));
    });

    testWidgets('RN-758 · no extrato, marcar a entrada a faz virar '
        'recebimento, e não despesa', (tester) async {
      final (_, book) = await _pick(
        tester,
        _proposal(DocumentKind.statement, lines: _statement),
      );
      final receipts = book().receipts.length;

      await _tap(tester, find.text('Salário'));
      await _tap(tester, find.text('Lançar 2 movimentações'));

      expect(book().receipts, hasLength(receipts + 1));
      expect(book().receipts.last.amount, const Money.fromCents(320000));
      final descriptions = book().entries.map((entry) => entry.description);
      expect(descriptions, isNot(contains('Salário')));
    });

    testWidgets('RN-758 · Pix recebido vira entrada, e não despesa', (
      tester,
    ) async {
      final (_, book) = await _pick(
        tester,
        _proposal(
          DocumentKind.incomeReceipt,
          amount: const Money.fromCents(12000),
        ),
      );
      final entries = book().entries.length;
      final receipts = book().receipts.length;

      expect(find.text('Dinheiro que entrou'), findsOneWidget);
      await _tap(tester, find.text('Registrar entrada'));

      expect(book().receipts, hasLength(receipts + 1));
      expect(book().receipts.last.amount, const Money.fromCents(12000));
      expect(book().entries, hasLength(entries));
    });

    testWidgets('se a leitura errou, "É uma despesa" leva à conferência de '
        'sempre', (tester) async {
      await _pick(
        tester,
        _proposal(
          DocumentKind.incomeReceipt,
          amount: const Money.fromCents(12000),
        ),
      );

      await _tap(tester, find.text('É uma despesa'));

      expect(find.text('Conferir comprovante'), findsOneWidget);
    });

    testWidgets('RN-756 · pagamento de fatura: "Não lançar" não grava nada e '
        'apaga o arquivo', (tester) async {
      final (inbox, book) = await _pick(
        tester,
        _proposal(
          DocumentKind.statementPayment,
          amount: const Money.fromCents(150000),
        ),
      );
      final entries = book().entries.length;

      expect(find.text('Pagamento de fatura'), findsOneWidget);
      await _tap(tester, find.text('Não lançar'));

      expect(book().entries, hasLength(entries));
      expect(inbox.discarded, contains('/inbox/doc'));
    });
  });
}
