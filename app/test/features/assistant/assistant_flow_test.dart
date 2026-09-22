import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/core/errors/error_texts.g.dart';
import 'package:cajui/src/features/assistant/application/answer_source.dart';
import 'package:cajui/src/features/assistant/application/assistant_gateway.dart';
import 'package:cajui/src/features/assistant/application/assistant_reply.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/scripted_assistant.dart';
import '../../support/test_scope.dart';

Future<void> _open(WidgetTester tester, {AssistantGateway? assistant}) async {
  tester.view.physicalSize = const Size(390, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(assistant: assistant),
      child: const CajuiApp(),
    ),
  );
  await _settle(tester);
  await tester.tap(find.bySemanticsLabel('Assistente'));
  await _settle(tester);
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

/// O espaço que o formatador põe entre `R$` e o número.
const String _nbsp = BrlFormatter.nbsp;

void main() {
  testWidgets('RN-960 · a conta que o Cajui já sabe fazer não vira token, '
      'nem precisa de servidor', (tester) async {
    final assistant = ScriptedAssistant(const [AssistantAnswered('não devia')]);
    await _open(tester, assistant: assistant);

    await tester.tap(find.text('Como o mês está fechando?'));
    await _settle(tester);

    // Respondido aqui dentro: o caminho do servidor nem foi tocado.
    expect(assistant.asked, isEmpty);
    expect(find.text('não devia'), findsNothing);
    expect(find.textContaining('setembro'), findsWidgets);
  });

  testWidgets('aparelho não cadastrado: a pergunta que precisa do servidor '
      'oferece o cadastro, e não um erro seco', (tester) async {
    await _open(tester);

    // Pergunta aberta: o domínio não responde, e aí o cadastro faz falta.
    await _ask(tester, 'vale a pena trocar de plano de celular?');
    await _settle(tester);

    expect(find.text('Esta pergunta precisa do servidor'), findsOneWidget);
    expect(find.text('Cadastrar este aparelho'), findsOneWidget);
  });

  testWidgets('RN-946 · a tela espera, e a resposta só aparece inteira; '
      'RN-947 · os números vêm com a origem', (tester) async {
    final assistant = ScriptedAssistant(const [
      AssistantAnswered(
        'Você gastou R\$${_nbsp}56,00 em dinheiro no mercado — fato, dos seus '
        'lançamentos.',
        sources: [
          AnswerSource(
            label: 'Gasto em Mercado, em dinheiro',
            cents: 5600,
            kind: 'fact',
            period: '2026-09',
          ),
        ],
      ),
    ])..hold();
    await _open(tester, assistant: assistant);

    // Pergunta aberta, das que só a IA responde: o domínio não tem conta
    // pronta para ela, então ela sobe.
    await _ask(tester, 'me explica o que é renda comprometida');
    await tester.pump();

    expect(find.bySemanticsLabel('Cajui está respondendo'), findsOneWidget);
    expect(find.textContaining('56,00'), findsNothing);

    assistant.release();
    await _settle(tester);

    expect(find.textContaining('em dinheiro no mercado'), findsOneWidget);
    await tester.tap(find.text('De onde vieram os números'));
    await tester.pump();
    expect(
      find.text(
        'Gasto em Mercado, em dinheiro: R\$${_nbsp}56,00 · fato, 2026-09',
      ),
      findsOneWidget,
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
