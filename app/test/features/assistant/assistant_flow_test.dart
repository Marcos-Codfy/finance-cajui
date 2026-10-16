import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/core/errors/error_texts.g.dart';
import 'package:cajui/src/features/assistant/application/assistant_action_done.dart';
import 'package:cajui/src/features/assistant/application/assistant_gateway.dart';
import 'package:cajui/src/features/assistant/application/assistant_reply.dart';
import 'package:cajui/src/features/budget/application/book_finances.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/today_controller.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/scripted_assistant.dart';
import '../../support/test_scope.dart';

Future<MemoryLedgerJournal> _open(
  WidgetTester tester, {
  AssistantGateway? assistant,
  List<LedgerEvent> events = const [],
}) async {
  tester.view.physicalSize = const Size(390, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final journal = MemoryLedgerJournal(events);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(assistant: assistant, journal: journal),
      child: const CajuiApp(),
    ),
  );
  await _settle(tester);
  await tester.tap(find.bySemanticsLabel('Conversar'));
  await _settle(tester);
  return journal;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

/// Digita a pergunta e manda, como quem usa o app.
Future<void> _ask(WidgetTester tester, String question) async {
  await tester.enterText(find.byType(EditableText), question);
  await tester.pump();
  await tester.tap(find.bySemanticsLabel('Enviar pergunta'));
}

/// A padaria de R$ 50,00 que o assistente lançou no servidor, já descida
/// para o livro daqui.
final Entry _padaria = Entry.create(
  id: 'ia-despesa-1',
  description: 'Padaria',
  amount: const Money.fromCents(5000),
  occurredOn: testToday,
  category: DefaultCatalog.emptyBook.categoryOf('bakery'),
  paymentLines: [
    DefaultCatalog.emptyBook.methodOf('pix').line(const Money.fromCents(5000)),
  ],
  today: testToday,
).valueOrNull!;

/// O espaço que o formatador põe entre `R$` e o número.
const String _nbsp = BrlFormatter.nbsp;

void main() {
  testWidgets('ADR-021 · toda pergunta vai ao servidor, inclusive a que o '
      'domínio saberia responder', (tester) async {
    final assistant = ScriptedAssistant(const [
      AssistantAnswered(r'Sobram R$ 920,00 neste mês.'),
    ]);
    await _open(tester, assistant: assistant);

    await tester.tap(find.widgetWithText(CajuiChip, 'Quanto sobra neste mês?'));
    await _settle(tester);

    expect(assistant.asked, ['Quanto sobra neste mês?']);
    expect(find.text(r'Sobram R$ 920,00 neste mês.'), findsOneWidget);
  });

  testWidgets('a pergunta leva os números do mês da tela, para a Juju não '
      'dizer outra sobra que a do Início', (tester) async {
    final assistant = ScriptedAssistant(const [AssistantAnswered('Certo.')]);
    await _open(tester, assistant: assistant, events: samplePlanEvents);

    await tester.tap(find.widgetWithText(CajuiChip, 'Quanto sobra neste mês?'));
    await _settle(tester);

    final scope = ProviderScope.containerOf(
      tester.element(find.byType(CajuiApp)),
    );
    final shown = MonthFigures.of(
      scope.read(financesProvider)!,
      scope.read(todayProvider),
    );
    final sent = assistant.months.single!;
    expect(sent.hasPlan, isTrue);
    expect(sent.toJson(), shown.toJson());
  });

  testWidgets('resposta com a sobra ganha o atalho para conferir no Meu mês', (
    tester,
  ) async {
    final assistant = ScriptedAssistant(const [
      AssistantAnswered(r'Sobram R$ 920,00 neste mês.'),
    ]);
    await _open(tester, assistant: assistant, events: samplePlanEvents);

    await tester.tap(find.widgetWithText(CajuiChip, 'Quanto sobra neste mês?'));
    await _settle(tester);
    await tester.tap(find.text('Ver no Meu mês'));
    await _settle(tester);

    expect(find.bySemanticsLabel('Voltar'), findsWidgets);
    expect(find.text('Ver no Meu mês'), findsNothing);
  });

  testWidgets('RN-946 · a tela espera, e a resposta só aparece inteira', (
    tester,
  ) async {
    final assistant = ScriptedAssistant(const [
      AssistantAnswered('Você gastou R\$${_nbsp}56,00 em dinheiro no mercado.'),
    ])..hold();
    await _open(tester, assistant: assistant);

    await _ask(tester, 'me explica o que é renda comprometida');
    await tester.pump();

    expect(find.bySemanticsLabel('Cajui está respondendo'), findsOneWidget);
    expect(find.textContaining('56,00'), findsNothing);

    assistant.release();
    await _settle(tester);

    expect(find.textContaining('em dinheiro no mercado'), findsOneWidget);
  });

  testWidgets('ADR-021 · "gastei 50 na padaria": o que o assistente lançou '
      'vem com Desfazer, e desfazer cancela o lançamento aqui', (tester) async {
    final assistant = ScriptedAssistant(const [
      AssistantAnswered(
        r'Lancei R$ 50,00 em Padaria, no Pix, hoje.',
        actions: [
          AssistantActionDone(
            kind: 'recorded',
            id: 'ia-despesa-1',
            label: 'Padaria',
            amountCents: 5000,
          ),
        ],
      ),
    ]);
    // O lançamento já desceu do servidor: é o que a sincronização depois
    // da resposta faz no app de verdade.
    final journal = await _open(
      tester,
      assistant: assistant,
      events: [EntryRecorded(_padaria)],
    );

    await _ask(tester, 'gastei 50 na padaria');
    await _settle(tester);

    expect(find.textContaining(r'Lancei R$ 50,00'), findsOneWidget);
    expect(find.text('Padaria · R\$${_nbsp}50,00'), findsOneWidget);
    await tester.tap(find.text('Desfazer'));
    await _settle(tester);

    expect(find.text('Desfeito'), findsOneWidget);
    final cancelled = (await journal.readAll()).whereType<EntryCancelled>();
    expect(cancelled.single.entryId, 'ia-despesa-1');
  });

  testWidgets('pergunta da Juju ganha "Pode" e "Não"; o toque responde, e a '
      'resposta seguinte, sem pergunta, não tem botão', (tester) async {
    final assistant = ScriptedAssistant(const [
      AssistantAnswered(r'Lanço R$ 800,00 como parcela da dívida?'),
      AssistantAnswered('Pronto.'),
    ]);
    await _open(tester, assistant: assistant);

    await _ask(tester, 'abate 800 da dívida');
    await _settle(tester);
    await tester.tap(find.widgetWithText(CajuiChip, 'Pode'));
    await _settle(tester);

    expect(assistant.asked, ['abate 800 da dívida', 'Pode']);
    expect(find.widgetWithText(CajuiChip, 'Pode'), findsNothing);
  });

  testWidgets('BL-117 · desfazer o abatimento cancela o lançamento e devolve '
      'o saldo da dívida', (tester) async {
    Debt version(int cents, int minute) => Debt.withBalance(
      id: 'debt-1',
      creditor: 'Banco do bairro',
      kind: DebtKind.loan,
      balance: Money.fromCents(cents),
      monthlyPayment: const Money.fromCents(10000),
      dueDay: 10,
      informedOn: LocalDate(2026, 9, 1),
      definedAt: DateTime.utc(2026, 9, 1, 12, minute),
    ).valueOrNull!;
    final assistant = ScriptedAssistant(const [
      AssistantAnswered(
        r'Abati R$ 50,00 da dívida.',
        actions: [
          AssistantActionDone(
            kind: 'paidDown',
            id: 'ia-despesa-1',
            label: 'Banco do bairro · abatimento',
            amountCents: 5000,
            debtId: 'debt-1',
          ),
        ],
      ),
    ]);
    final journal = await _open(
      tester,
      assistant: assistant,
      events: [
        DebtDefined(id: 'f1', debt: version(100000, 0)),
        DebtDefined(id: 'f2', debt: version(95000, 5)),
        EntryRecorded(_padaria),
      ],
    );

    await _ask(tester, 'abate 50 da dívida');
    await _settle(tester);
    await tester.tap(find.text('Desfazer'));
    await _settle(tester);

    final events = await journal.readAll();
    expect(events.whereType<EntryCancelled>().single.entryId, 'ia-despesa-1');
    expect(
      events.whereType<DebtDefined>().last.debt.informedBalance,
      const Money.fromCents(100000),
    );
  });

  testWidgets('E-AI-01 · IA fora do ar: a frase do assistente, e perguntar de '
      'novo refaz a mesma pergunta', (tester) async {
    final assistant = ScriptedAssistant(const [
      AssistantFailed(ErrorCode.ai01),
      AssistantAnswered('Certo.'),
    ]);
    await _open(tester, assistant: assistant);

    await _ask(tester, 'me explica o que é renda comprometida');
    await _settle(tester);

    expect(
      find.text(
        'O assistente está fora do ar. Seus números continuam no painel, e '
        'lançar funciona normalmente.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Na captura'), findsNothing);

    await tester.tap(find.text('Perguntar de novo'));
    await _settle(tester);

    expect(assistant.asked, [
      'me explica o que é renda comprometida',
      'me explica o que é renda comprometida',
    ]);
    expect(find.text('Certo.'), findsOneWidget);
    expect(find.text('Perguntar de novo'), findsNothing);
  });

  test(
    'o catálogo traz uma frase por tela no E-AI-01, e cada tela usa a sua',
    () {
      final text = ErrorTexts.of(ErrorCode.ai01);

      expect(
        text.inContext('Na captura').message,
        startsWith('A classificação automática está fora do ar.'),
      );
      expect(
        text.inContext('No assistente').message,
        startsWith('O assistente está fora do ar.'),
      );
      expect(
        ErrorTexts.of(ErrorCode.net01).inContext('No assistente').message,
        ErrorTexts.of(ErrorCode.net01).message,
      );
    },
  );
}
