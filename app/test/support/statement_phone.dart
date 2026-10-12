import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/receipts/application/read_outcome.dart';
import 'package:cajui/src/features/receipts/application/shared_item.dart';
import 'package:cajui/src/features/statements/application/statement_page_source.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_inbox.dart';
import 'fake_page_source.dart';
import 'fake_reader.dart';
import 'memory_ledger_journal.dart';
import 'sample_plan.dart';
import 'test_scope.dart';

/// O extrato FICTÍCIO de setembro, como o celular leu: cinco linhas.
const septemberPage =
    '01/09 ASSAI ATACADISTA 412,30\n'
    '03/09 IFD*RESTAURANTE SABOR 45,90\n'
    '05/09 PIX ENVIADO JOAO P SILVA 150,00\n'
    '08/09 PAGAMENTO DE FATURA 1.200,00\n'
    '10/09 LOJA ESTRELA 89,90';

/// O que a IA devolveu de cada linha de [septemberPage].
const septemberMovements = [
  StatementMovement(
    sourceLine: 1,
    day: 1,
    month: 9,
    description: 'Assaí Atacadista',
    amount: Money.fromCents(41230),
    categoryId: 'groceries',
    confidence: Confidence.high,
  ),
  StatementMovement(
    sourceLine: 2,
    day: 3,
    month: 9,
    description: 'Restaurante Sabor',
    amount: Money.fromCents(4590),
    categoryId: 'eating-out',
  ),
  StatementMovement(
    sourceLine: 3,
    day: 5,
    month: 9,
    description: 'Pix para [NOME]',
    amount: Money.fromCents(15000),
    doubtful: true,
  ),
  StatementMovement(
    sourceLine: 4,
    day: 8,
    month: 9,
    description: 'Pagamento de fatura',
    amount: Money.fromCents(120000),
    kind: StatementLineKind.cardPayment,
  ),
  StatementMovement(
    sourceLine: 5,
    day: 10,
    month: 9,
    description: 'Loja Estrela',
    amount: Money.fromCents(8990),
    categoryId: 'home',
  ),
];

/// A leitura de páginas que devolve o extrato de setembro.
FakePageSource septemberSource([
  List<StatementMovement> movements = septemberMovements,
]) => FakePageSource({
  1: [pageRead(movements: movements, period: const BudgetMonth(2026, 9))],
});

/// O celular com o app aberto, para compartilhar extratos.
final class StatementPhone {
  /// Cria o celular.
  new(this.inbox, this.container);

  /// A caixa por onde o compartilhamento chega.
  final FakeInbox inbox;

  /// Os providers do app aberto.
  final ProviderContainer container;

  /// O livro agora.
  LedgerBook get book => container.read(ledgerProvider).requireValue;

  /// Compartilha o extrato do app do banco, de novo se for o caso.
  Future<void> share(WidgetTester tester, String id) async {
    inbox.share([SharedFile(id: id, path: '/inbox/extrato', isPdf: true)]);
    await settleStatement(tester);
  }
}

/// Deixa a leitura e as animações assentarem.
Future<void> settleStatement(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Abre o app com o plano de exemplo e [events] no livro; as páginas são
/// lidas por [pages].
Future<StatementPhone> openStatementPhone(
  WidgetTester tester, {
  FakePageSource? pages,
  List<LedgerEvent> events = const [],
  String page = septemberPage,
}) async {
  tester.view.physicalSize = const Size(420, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final inbox = FakeInbox();
  await tester.pumpWidget(
    ProviderScope(
      overrides: _overrides(inbox, pages ?? septemberSource(), events, page),
      child: const CajuiApp(),
    ),
  );
  await tester.pump();
  return StatementPhone(
    inbox,
    ProviderScope.containerOf(tester.element(find.byType(CajuiApp))),
  );
}

List<Override> _overrides(
  FakeInbox inbox,
  FakePageSource pages,
  List<LedgerEvent> events,
  String page,
) => [
  ...testOverrides(
    journal: MemoryLedgerJournal([...samplePlanEvents, ...events]),
    inbox: inbox,
    reader: FakeReader({
      '/inbox/extrato': ReadText(page, pages: [page], pageCount: 1),
    }),
  ),
  statementPageSourceProvider.overrideWithValue(pages),
];

/// Toca no botão ou na opção [label] da conversa.
Future<void> chooseInStatement(WidgetTester tester, String label) async {
  final target = find.text(label).last;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await settleStatement(tester);
}

/// Confere os dois blocos, responde as duas dúvidas e lança.
Future<void> talkThroughSeptember(WidgetTester tester) async {
  for (final label in [
    'Confere',
    'Confere',
    'Alguém da casa',
    'Casa',
    'Pode lançar (3)',
  ]) {
    await chooseInStatement(tester, label);
  }
}
