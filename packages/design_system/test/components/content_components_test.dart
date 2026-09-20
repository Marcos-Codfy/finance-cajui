import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

/// "R$" seguido do espaço que não quebra linha, como o formatador escreve.
const _rs = 'R\$${BrlFormatter.nbsp}';

void main() {
  group('BrlFormatter', () {
    test('os caracteres especiais são os certos, e não parecidos', () {
      expect(BrlFormatter.nbsp.codeUnits, [0xA0]);
      expect(BrlFormatter.minus.codeUnits, [0x2212]);
    });

    test('escreve reais com milhar em ponto e centavos em vírgula', () {
      expect(BrlFormatter.format(128450), '${_rs}1.284,50');
      expect(BrlFormatter.format(850), '${_rs}8,50');
      expect(BrlFormatter.format(0), '${_rs}0,00');
      expect(BrlFormatter.format(100000000), '${_rs}1.000.000,00');
    });

    test('usa o sinal de menos verdadeiro, nunca hífen', () {
      final shortfall = BrlFormatter.format(-14200);

      expect(shortfall, '${BrlFormatter.minus}${_rs}142,00');
      expect(shortfall, isNot(contains('-')));
    });

    test('omite centavos zerados só quando pedido', () {
      expect(BrlFormatter.format(41200, hideZeroCents: true), '${_rs}412');
      expect(BrlFormatter.format(10647, hideZeroCents: true), '${_rs}106,47');
    });
  });

  group('CajuiAmountText', () {
    testWidgets('anuncia o valor completo ao leitor de tela', (tester) async {
      await tester.pumpWidget(host(const CajuiAmountText(10647, large: true)));

      expect(find.bySemanticsLabel('${_rs}106,47'), findsOneWidget);
    });

    testWidgets('a falta usa a cor escolhida para a falta do mês', (
      tester,
    ) async {
      final theme = CajuiThemeData.light(shortfallStyle: ShortfallStyle.alarm);
      await tester.pumpWidget(
        host(
          const CajuiAmountText(-14200, tone: CajuiAmountTone.shortfall),
          theme: theme,
        ),
      );

      final text = tester.widget<Text>(find.byType(Text));
      final number = (text.textSpan! as TextSpan).children!.last as TextSpan;
      expect(number.style!.color, theme.colors.intent.danger);
    });
  });

  group('CajuiMeter', () {
    testWidgets('traz o valor por extenso e não trava ao passar do limite', (
      tester,
    ) async {
      const spoken = '260 reais de 236 reais e 25 centavos';
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 200,
            child: CajuiMeter(
              value: 1.1,
              semanticLabel: 'Limite da semana',
              semanticValue: spoken,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final node = tester.getSemantics(find.byType(CajuiMeter));
      expect(node.label, 'Limite da semana');
      expect(node.value, spoken);
    });
  });

  group('CajuiConfidenceIndicator', () {
    testWidgets('diz a confiança em texto, não só em pontos', (tester) async {
      await tester.pumpWidget(
        host(const CajuiConfidenceIndicator(CajuiConfidenceLevel.medium)),
      );

      expect(find.text('Fiquei entre estas'), findsOneWidget);
    });
  });

  group('CajuiCard e CajuiListRow', () {
    testWidgets('cartão tocável tem um nome só para o leitor de tela', (
      tester,
    ) async {
      const name = 'Fatura do cartão final 4821';
      var opened = 0;
      await tester.pumpWidget(
        host(
          CajuiCard(
            onPressed: () => opened++,
            semanticLabel: name,
            child: const Text('Fatura'),
          ),
        ),
      );

      await tester.tap(find.text('Fatura'));

      expect(opened, 1);
      expect(find.bySemanticsLabel(name), findsOneWidget);
    });

    testWidgets('a linha mostra o que foi e por onde foi pago', (tester) async {
      await tester.pumpWidget(
        host(
          const CajuiListRow(
            title: 'Mercado',
            subtitle: 'Vale alimentação',
            trailing: CajuiAmountText(3840),
          ),
        ),
      );

      expect(find.text('Mercado'), findsOneWidget);
      expect(find.text('Vale alimentação'), findsOneWidget);
    });
  });
}
