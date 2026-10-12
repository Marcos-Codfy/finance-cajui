import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/receipts/application/read_outcome.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:cajui/src/features/receipts/application/shared_item.dart';
import 'package:cajui/src/features/statements/application/statement_page_source.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_inbox.dart';
import '../../support/fake_page_source.dart';
import '../../support/fake_reader.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/pick_document.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

/// O extrato de setembro, como o celular leu: cinco linhas.
const _page =
    '01/09 ASSAI ATACADISTA 412,30\n'
    '03/09 IFD*RESTAURANTE SABOR 45,90\n'
    '05/09 PIX ENVIADO JOAO P SILVA 150,00\n'
    '08/09 PAGAMENTO DE FATURA 1.200,00\n'
    '10/09 LOJA ESTRELA 89,90';

/// O que a IA devolveu de cada linha.
final _movements = [
  const StatementMovement(
    sourceLine: 1,
    day: 1,
    month: 9,
    description: 'Assaí Atacadista',
    amount: Money.fromCents(41230),
    categoryId: 'groceries',
    confidence: Confidence.high,
  ),
  const StatementMovement(
    sourceLine: 2,
    day: 3,
    month: 9,
    description: 'Restaurante Sabor',
    amount: Money.fromCents(4590),
    categoryId: 'eating-out',
  ),
  const StatementMovement(
    sourceLine: 3,
    day: 5,
    month: 9,
    description: 'Pix para [NOME]',
    amount: Money.fromCents(15000),
    doubtful: true,
  ),
  const StatementMovement(
    sourceLine: 4,
    day: 8,
    month: 9,
    description: 'Pagamento de fatura',
    amount: Money.fromCents(120000),
    kind: StatementLineKind.cardPayment,
  ),
  const StatementMovement(
    sourceLine: 5,
    day: 10,
    month: 9,
    description: 'Loja Estrela',
    amount: Money.fromCents(8990),
    categoryId: 'home',
  ),
];

final class _Phone {
  new(this.inbox, this.container);

  final FakeInbox inbox;
  final ProviderContainer container;

  LedgerBook get book => container.read(ledgerProvider).requireValue;

  /// Compartilha o extrato do app do banco, de novo se for o caso.
  Future<void> share(WidgetTester tester, String id) async {
    inbox.share([SharedFile(id: id, path: '/inbox/extrato', isPdf: true)]);
    await _settle(tester);
  }
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// O que a leitura entende do arquivo: um extrato, e as cinco linhas.
List<Override> _reads(FakeInbox inbox) => [
  ...testOverrides(
    journal: MemoryLedgerJournal(samplePlanEvents),
    inbox: inbox,
    reader: FakeReader(const {
      '/inbox/extrato': ReadText(_page, pages: [_page], pageCount: 1),
    }),
  ),
  receiptClassifierProvider.overrideWithValue(
    ReadsAs(
      proposalOf(
        DocumentKind.statement,
        lines: [
          StatementLine(
            occurredOn: LocalDate(2026, 9, 1),
            description: 'Assaí',
            amount: const Money.fromCents(41230),
          ),
        ],
      ),
    ),
  ),
  statementPageSourceProvider.overrideWithValue(
    FakePageSource({
      1: [pageRead(movements: _movements, period: const BudgetMonth(2026, 9))],
    }),
  ),
];

Future<_Phone> _open(WidgetTester tester) async {
  tester.view.physicalSize = const Size(420, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final inbox = FakeInbox();
  await tester.pumpWidget(
    ProviderScope(overrides: _reads(inbox), child: const CajuiApp()),
  );
  await tester.pump();
  return _Phone(
    inbox,
    ProviderScope.containerOf(tester.element(find.byType(CajuiApp))),
  );
}

Future<void> _choose(WidgetTester tester, String label) async {
  final target = find.text(label).last;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await _settle(tester);
}

/// Confere os dois blocos, responde as duas dúvidas e lança.
Future<void> _talkThrough(WidgetTester tester) async {
  await _choose(tester, 'Confere');
  await _choose(tester, 'Confere');
  await _choose(tester, 'Alguém da casa');
  await _choose(tester, 'Casa');
  await _choose(tester, 'Pode lançar (3)');
}

void main() {
  testWidgets('RN-1100 e RN-1112 · o extrato compartilhado abre na conversa '
      'da Juju, com o resumo, e fica em "Para conferir" até lançar', (
    tester,
  ) async {
    final phone = await _open(tester);
    await phone.share(tester, 'extrato-1');

    expect(
      find.textContaining('Li 5 movimentações de 1 a 10 de setembro.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('1 pagamento de fatura não conta'),
      findsOneWidget,
    );
    expect(find.textContaining('2 ficaram em dúvida'), findsOneWidget);
    expect(find.text('Pode lançar (2)'), findsOneWidget);
    final pending = await phone.container.read(pendingCapturesProvider.future);
    expect(pending.map((item) => item.id), ['extrato-1']);
  });

  testWidgets('RN-1113 a RN-1116 · confere por blocos, pergunta as dúvidas, '
      'lembra as respostas e lança só no fim', (tester) async {
    final phone = await _open(tester);
    await phone.share(tester, 'extrato-1');

    expect(find.textContaining('Mercado — 1 compra'), findsOneWidget);
    await _choose(tester, 'Ver as linhas');
    expect(find.text('01/09 · Assaí Atacadista'), findsOneWidget);
    await _choose(tester, 'Confere');
    // A marca: "IFD*" é iFood, e cai em Restaurante e lanche sem perguntar.
    expect(
      find.textContaining('Restaurante e lanche — 1 compra'),
      findsOneWidget,
    );
    expect(phone.book.entries, isEmpty, reason: 'nada antes de lançar');

    await _choose(tester, 'Confere');
    expect(find.textContaining('Pix para Joao P Silva'), findsOneWidget);
    await _choose(tester, 'Alguém da casa');
    expect(find.textContaining('Loja Estrela'), findsWidgets);
    await _choose(tester, 'Casa');
    await _choose(tester, 'Pode lançar (3)');

    expect(phone.book.entries.map((entry) => entry.description).toSet(), {
      'Assaí Atacadista',
      'iFood',
      'Loja Estrela',
    });
    final memory = phone.book.learnedAnswers;
    expect(
      memory.forKey('pessoa:joao p silva')!.treatment,
      LineTreatment.household,
    );
    expect(memory.forKey('loja estrela')!.categoryId, 'home');
    final pending = await phone.container.read(pendingCapturesProvider.future);
    expect(pending, isEmpty, reason: 'lançado, a captura fecha');
  });

  testWidgets('RN-1117 · ler o mesmo extrato de novo não lança em dobro, e '
      'as respostas lembradas não perguntam de novo', (tester) async {
    final phone = await _open(tester);
    await phone.share(tester, 'extrato-1');
    await _talkThrough(tester);
    await _choose(tester, 'Pronto');

    await phone.share(tester, 'extrato-2');

    expect(find.textContaining('3 já estavam no Cajui'), findsOneWidget);
    expect(find.textContaining('em dúvida'), findsNothing);
    expect(find.text('Pode lançar (0)'), findsOneWidget);
    expect(phone.book.entries, hasLength(3));
  });

  testWidgets('RN-1119 · desfazer tira os lançamentos do lote, e lançar de '
      'novo grava outra vez, com chaves novas', (tester) async {
    final phone = await _open(tester);
    await phone.share(tester, 'extrato-1');
    await _talkThrough(tester);
    final first = {for (final entry in phone.book.entries) entry.id};

    await _choose(tester, 'Desfazer tudo');
    expect(phone.book.entries, isEmpty);
    expect(find.textContaining('Desfiz os 3 lançamentos'), findsOneWidget);
    await _choose(tester, 'Pronto');

    await phone.share(tester, 'extrato-2');
    await _choose(tester, 'Confere');
    await _choose(tester, 'Confere');
    await _choose(tester, 'Pode lançar (3)');

    final again = {for (final entry in phone.book.entries) entry.id};
    expect(again, hasLength(3));
    expect(again.intersection(first), isEmpty);
  });

  testWidgets('"Conferir depois" fecha a conversa sem gravar nada', (
    tester,
  ) async {
    final phone = await _open(tester);
    await phone.share(tester, 'extrato-1');

    await _choose(tester, 'Conferir depois');

    expect(phone.book.entries, isEmpty);
    expect(find.byType(CajuiChatPrompt), findsNothing);
  });
}
