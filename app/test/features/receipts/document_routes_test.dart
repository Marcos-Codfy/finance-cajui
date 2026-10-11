import 'package:cajui/src/features/receipts/application/capture_route.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pick_document.dart';

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

void main() {
  group('para onde vai o documento lido', () {
    test('fatura que só a IA viu vai para a tela que pergunta; "extrato" sem '
        'linhas é compra', () {
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

      expect(CaptureRoute.of(doubt), CaptureRoute.notAnExpense);
      expect(
        CaptureRoute.of(proposalOf(DocumentKind.statement)),
        CaptureRoute.expense,
      );
      expect(
        CaptureRoute.of(proposalOf(DocumentKind.ownTransfer)),
        CaptureRoute.notAnExpense,
      );
    });

    testWidgets('RN-707 · extrato: as despesas novas vêm marcadas, e só elas '
        'viram lançamento', (tester) async {
      final (_, book) = await pickDocument(
        tester,
        proposalOf(DocumentKind.statement, lines: _statement),
      );
      final receipts = book().receipts.length;

      expect(find.textContaining('não é despesa'), findsOneWidget);
      await tapAndSettle(tester, find.text('Lançar 1 movimentação'));

      final descriptions = book().entries.map((entry) => entry.description);
      expect(descriptions, contains('Padaria Central'));
      expect(descriptions, isNot(contains('Fatura do cartão')));
      expect(book().receipts, hasLength(receipts));
    });

    testWidgets('RN-758 · no extrato, marcar a entrada a faz virar '
        'recebimento, e não despesa', (tester) async {
      final (_, book) = await pickDocument(
        tester,
        proposalOf(DocumentKind.statement, lines: _statement),
      );
      final receipts = book().receipts.length;

      await tapAndSettle(tester, find.text('Salário'));
      await tapAndSettle(tester, find.text('Lançar 2 movimentações'));

      expect(book().receipts, hasLength(receipts + 1));
      expect(book().receipts.last.amount, const Money.fromCents(320000));
      final descriptions = book().entries.map((entry) => entry.description);
      expect(descriptions, isNot(contains('Salário')));
    });

    testWidgets('RN-758 · Pix recebido vira entrada, e não despesa', (
      tester,
    ) async {
      final (_, book) = await pickDocument(
        tester,
        proposalOf(
          DocumentKind.incomeReceipt,
          amount: const Money.fromCents(12000),
        ),
      );
      final entries = book().entries.length;
      final receipts = book().receipts.length;

      expect(find.text('Dinheiro que entrou'), findsOneWidget);
      await tapAndSettle(tester, find.text('Registrar entrada'));

      expect(book().receipts, hasLength(receipts + 1));
      expect(book().receipts.last.amount, const Money.fromCents(12000));
      expect(book().entries, hasLength(entries));
    });

    testWidgets('se a leitura errou, "É uma despesa" leva à conferência de '
        'sempre', (tester) async {
      await pickDocument(
        tester,
        proposalOf(
          DocumentKind.incomeReceipt,
          amount: const Money.fromCents(12000),
        ),
      );

      await tapAndSettle(tester, find.text('É uma despesa'));

      expect(find.text('Conferir comprovante'), findsOneWidget);
    });

    testWidgets('RN-756 · pagamento de fatura: "Não lançar" não grava nada e '
        'apaga o arquivo', (tester) async {
      final (inbox, book) = await pickDocument(
        tester,
        proposalOf(
          DocumentKind.statementPayment,
          amount: const Money.fromCents(150000),
        ),
      );
      final entries = book().entries.length;

      expect(find.text('Pagamento de fatura'), findsOneWidget);
      await tapAndSettle(tester, find.text('Não lançar'));

      expect(book().entries, hasLength(entries));
      expect(inbox.discarded, contains('/inbox/doc'));
    });
  });
}
