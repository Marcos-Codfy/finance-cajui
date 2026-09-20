import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart' show TextField;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

void main() {
  group('CentsInputFormatter', () {
    const formatter = CentsInputFormatter();
    TextEditingValue type(String text) => formatter.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: text),
    );

    test('os dígitos entram pela direita, sem digitar a vírgula', () {
      expect(type('1').text, '0,01');
      expect(type('12').text, '0,12');
      expect(type('123').text, '1,23');
      expect(type('128450').text, '1.284,50');
    });

    test('ignora o que não é dígito e lê de volta em centavos', () {
      expect(type(r'R$ 1.2a3').text, '1,23');
      expect(CentsInputFormatter.parse('1.284,50'), 128450);
      expect(CentsInputFormatter.parse(''), 0);
    });

    test('recusa valor acima do limite de dígitos', () {
      const previous = TextEditingValue(text: '9.999.999,99');
      final result = formatter.formatEditUpdate(
        previous,
        const TextEditingValue(text: '9.999.999,999'),
      );

      expect(result, previous);
    });
  });

  group('CajuiAmountField', () {
    testWidgets('entrega centavos inteiros a cada dígito', (tester) async {
      final received = <int>[];
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: CajuiAmountField(label: 'Valor', onChanged: received.add),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '4690');

      expect(received.last, 4690);
      expect(find.text('46,90'), findsOneWidget);
    });
  });

  group('CajuiTextField', () {
    testWidgets('o rótulo fica visível e o erro aparece em texto, com ícone', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 300,
            child: CajuiTextField(
              label: 'O que foi',
              error: 'Faltou dizer o que foi comprado.',
            ),
          ),
        ),
      );

      expect(find.text('O que foi'), findsOneWidget);
      expect(find.text('Faltou dizer o que foi comprado.'), findsOneWidget);
      expect(find.byType(CajuiIcon), findsOneWidget);
    });
  });

  group('CajuiSelectField', () {
    testWidgets('vazio é um estado de primeira classe, dito ao leitor de tela', (
      tester,
    ) async {
      var opened = 0;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: CajuiSelectField(
              label: 'Categoria',
              onPressed: () => opened++,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Escolher'));

      expect(opened, 1);
      expect(
        find.bySemanticsLabel('Categoria: nada escolhido'),
        findsOneWidget,
      );
    });
  });

  group('CajuiOptionList', () {
    testWidgets('marca a escolhida com ícone e avisa a tocada', (tester) async {
      String? picked;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 300,
            child: CajuiOptionList<String>(
              options: const ['Transporte', 'Alimentação'],
              labelOf: (option) => option,
              selected: 'Transporte',
              onSelected: (option) => picked = option,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Alimentação'));

      expect(picked, 'Alimentação');
      expect(find.byType(CajuiIcon), findsOneWidget);
    });
  });
}
