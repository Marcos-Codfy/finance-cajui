import 'package:cajui/src/features/receipts/application/capture_route.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/pick_document.dart';

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
