import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

void main() {
  group('CajuiChatPrompt · a fala que pede resposta', () {
    testWidgets('RN-1113 · o bloco: texto, a lista curta e os botões', (
      tester,
    ) async {
      final pressed = <String>[];
      await tester.pumpWidget(
        host(
          CajuiChatPrompt(
            r'Mercado — 12 compras, R$ 1.240,00. Confere?',
            speaker: 'Juju',
            rows: const [
              (label: 'Assaí', value: r'R$ 412,30'),
              (label: 'Atacadão', value: r'R$ 380,00'),
            ],
            more: 'e mais 10',
            actions: [
              (
                label: 'Confere',
                onPressed: () => pressed.add('ok'),
                primary: true,
              ),
              (
                label: 'Corrigir',
                onPressed: () => pressed.add('fix'),
                primary: false,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Assaí'), findsOneWidget);
      expect(find.text('e mais 10'), findsOneWidget);
      await tester.tap(find.text('Corrigir'));
      await tester.tap(find.text('Confere'));
      expect(pressed, ['fix', 'ok']);
    });

    testWidgets('RN-1114 · as opções viram chips, uma escolha só', (
      tester,
    ) async {
      String? chosen;
      await tester.pumpWidget(
        host(
          CajuiChatPrompt(
            r'Pix para João P Silva, R$ 150,00, em 12/10. O que foi?',
            options: const ['É um gasto', 'Alguém da casa', 'Não lançar'],
            onOption: (option) => chosen = option,
          ),
        ),
      );

      await tester.tap(find.text('Alguém da casa'));

      expect(chosen, 'Alguém da casa');
    });

    testWidgets('o leitor de tela lê a fala inteira uma vez, e cada botão '
        'continua sendo um botão com nome', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          CajuiChatPrompt(
            'Padaria — 3 compras. Confere?',
            speaker: 'Juju',
            rows: const [(label: 'Padaria Boa Vista', value: r'R$ 8,00')],
            actions: [(label: 'Confere', onPressed: () {}, primary: true)],
          ),
        ),
      );

      expect(
        find.bySemanticsLabel(
          RegExp(r'^Juju: Padaria — 3 compras\. Confere\?\. Padaria Boa Vista'),
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Confere'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('respondida, a fala fica sem botões', (tester) async {
      await tester.pumpWidget(host(const CajuiChatPrompt('Confere?')));

      expect(find.byType(CajuiButton), findsNothing);
      expect(find.byType(CajuiChip), findsNothing);
    });
  });
}
