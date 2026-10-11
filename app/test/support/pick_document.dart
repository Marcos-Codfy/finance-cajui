import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/receipts/application/read_outcome.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:cajui/src/features/receipts/application/shared_item.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_inbox.dart';
import 'fake_reader.dart';
import 'memory_ledger_journal.dart';
import 'sample_plan.dart';
import 'test_scope.dart';

/// Toca em [finder] e deixa a animação assentar.
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

/// O que a leitura teria entendido do documento.
final class ReadsAs implements ReceiptClassifier {
  /// Cria o classificador que devolve sempre [proposal].
  const new(this.proposal);

  /// A proposta devolvida.
  final EntryProposal proposal;

  @override
  Future<EntryProposal> classify(ClassificationRequest request) async =>
      proposal;
}

/// Uma proposta do tipo [kind], lida em 12/09/2026.
EntryProposal proposalOf(
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

Widget _app(
  FakeInbox inbox,
  EntryProposal proposal,
  List<LedgerEvent> events,
) => ProviderScope(
  overrides: [
    ...testOverrides(
      journal: MemoryLedgerJournal([...samplePlanEvents, ...events]),
      inbox: inbox,
      reader: FakeReader(const {
        '/inbox/doc': ReadText('documento lido no aparelho'),
      }),
    ),
    receiptClassifierProvider.overrideWithValue(ReadsAs(proposal)),
  ],
  child: const CajuiApp(),
);

/// Abre o app com o plano de exemplo, escolhe um documento da galeria que
/// a leitura entende como [proposal], e devolve a caixa de entrada e com o
/// que conferir o livro depois. [events] entra no livro depois do plano.
Future<(FakeInbox, LedgerBook Function())> pickDocument(
  WidgetTester tester,
  EntryProposal proposal, {
  List<LedgerEvent> events = const [],
}) async {
  tester.view.physicalSize = const Size(390, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final inbox = FakeInbox();
  await tester.pumpWidget(_app(inbox, proposal, events));
  await tester.pump();
  await tapAndSettle(tester, find.bySemanticsLabel('Lançamentos'));
  inbox.picked = const [
    SharedFile(id: 'doc', path: '/inbox/doc', isPdf: false),
  ];
  await tapAndSettle(tester, find.text('Da galeria'));
  final container = ProviderScope.containerOf(
    tester.element(find.byType(CajuiApp)),
  );
  return (inbox, () => container.read(ledgerProvider).value!);
}
