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

void main() {
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
