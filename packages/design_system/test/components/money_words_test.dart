import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

List<String> _money(String text) {
  final words = MoneyWords.split(text);
  return [
    for (final (index, word) in words.indexed)
      if (MoneyWords.isMoney(words, index)) word.trim(),
  ];
}

void main() {
  group('os valores em destaque na fala da Juju', () {
    test(r'o "R$" e o número ficam em destaque; o resto, não', () {
      expect(_money(r'Sobram R$ 530,90 neste mês, e o vale cobre R$ 400,00.'), [
        r'R$',
        '530,90',
        r'R$',
        '400,00.',
      ]);
      expect(_money(r'Entra R$ 3.467,35.'), [r'R$', '3.467,35.']);
    });

    test(r'número solto, sem "R$", não vira dinheiro', () {
      expect(_money('Faltam 3 dias e 12 contas.'), isEmpty);
      expect(_money(r'R$ é o símbolo.'), isEmpty);
    });

    testWidgets('a resposta que já chegou mostra o valor mais forte', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const CajuiChatBubble(r'Sobram R$ 530,90 neste mês.')),
      );

      final rich = tester
          .widgetList<RichText>(find.byType(RichText))
          .firstWhere((text) => text.text.toPlainText().contains('530,90'));
      final strong = <String>[];
      rich.text.visitChildren((span) {
        if (span is TextSpan &&
            span.text != null &&
            span.style?.fontVariations == MoneyWords.weight) {
          strong.add(span.text!.trim());
        }
        return true;
      });
      expect(strong, [r'R$', '530,90']);
    });
  });
}
