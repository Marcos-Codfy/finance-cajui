import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

void main() {
  group('a conta rápida do campo de valor', () {
    const formatter = CentsInputFormatter();
    TextEditingValue edit(String before, String after) =>
        formatter.formatEditUpdate(
          TextEditingValue(text: before),
          TextEditingValue(text: after),
        );

    test('cada valor somado se formata sozinho, e a leitura é a soma', () {
      expect(edit('35,00', '35,00 + 12').text, '35,00 + 0,12');
      expect(edit('', '3500 + 1200').text, '35,00 + 12,00');
      expect(CentsInputFormatter.parse('35,00 + 12,00'), 4700);
      expect(CentsInputFormatter.terms('35,00 + 12,00'), [3500, 1200]);
    });

    test('apagar logo depois do "+" tira a soma vazia, sem prender', () {
      expect(edit('35,00 + ', '35,00 +').text, '35,00');
      expect(edit('35,00 + 0,01', '35,00 + 0,0').text, '35,00 + ');
    });

    test('cada valor tem o seu limite de dígitos', () {
      const before = '9.999.999,99 + ';
      expect(edit(before, '${before}1234567890').text, before);
    });

    testWidgets('o botão começa outro valor, e a dica vira o total', (
      tester,
    ) async {
      final sums = <int>[];
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 360,
            child: CajuiAmountField(label: 'Valor', onChanged: sums.add),
          ),
        ),
      );

      await tester.enterText(find.byType(EditableText), '3500');
      await tester.tap(find.text('Somar outro valor'));
      await tester.pump();
      final field = find.byType(EditableText);
      final now = tester.widget<EditableText>(field).controller.text;
      await tester.enterText(field, '${now}1200');
      await tester.pump();

      expect(sums.last, 4700);
      expect(find.textContaining('47,00'), findsWidgets);
    });
  });
}
