import 'package:design_system/design_system.dart';
import 'package:design_system/src/components/credit_card/card_limit_usage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

const _rs = 'R\$${BrlFormatter.nbsp}';
const _front = 'Cartão Ipê, final 4821. Toque para ver o limite.';

Widget _card({
  int used = 124000,
  CajuiThemeData? theme,
  double textScale = 1,
  ValueChanged<bool>? onFlip,
  bool scrolling = false,
}) {
  final card = MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: SizedBox(
      width: 328,
      child: CajuiCreditCard3D(
        name: 'Cartão Ipê',
        lastDigits: '4821',
        usedCents: used,
        limitCents: 200000,
        onFlip: onFlip,
      ),
    ),
  );
  // Numa lista de verdade — e que tenha o que rolar —, o arrasto de cima
  // para baixo é da rolagem.
  final list = SingleChildScrollView(
    child: Column(children: [card, const SizedBox(height: 2000)]),
  );
  return host(scrolling ? list : card, theme: theme);
}

/// O quanto o cartão está girado de lado e para a frente, lido da matriz
/// de perspectiva que o desenha.
(double, double) _lean(WidgetTester tester) {
  final card = tester
      .widgetList<Transform>(
        find.descendant(
          of: find.byType(CajuiCreditCard3D),
          matching: find.byType(Transform),
        ),
      )
      .firstWhere((transform) => transform.transform.entry(3, 2) != 0);
  return (card.transform.entry(0, 2), card.transform.entry(1, 2));
}

Future<void> _drag(WidgetTester tester, Offset step) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byType(CajuiCreditCard3D)),
  );
  for (var i = 0; i < 4; i++) {
    await gesture.moveBy(step);
    await tester.pump(const Duration(milliseconds: 16));
  }
  // A mola anda em passos de quadro: vinte quadros curtos, e não um longo.
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  addTearDown(gesture.up);
}

void main() {
  final light = CajuiThemeData.light();
  final reduced = CajuiThemeData.light(motionLevel: MotionLevel.reduced);

  group('CardLimitUsage', () {
    CardLimitUsage usage(int used) =>
        CardLimitUsage(usedCents: used, limitCents: 200000);

    test('os degraus de 50% e 80% mudam o tom da barra', () {
      final colors = light.colors;

      expect(usage(98000).fill(colors), colors.intent.positive);
      expect(usage(100000).fill(colors), colors.data.variable);
      expect(usage(160000).fill(colors), colors.shortfall);
    });

    test('a frase descreve o fato, sem alarme', () {
      expect(usage(98000).note, 'A maior parte do limite está livre');
      expect(usage(100000).note, 'Metade do limite já está em uso');
      expect(usage(160000).note, 'Mais de 80% do limite está em uso');
      expect(usage(200000).note, 'O limite inteiro está em uso');
      expect(usage(220000).note, 'Passou ${_rs}200,00 do limite');
      for (final used in [98000, 100000, 160000, 200000, 220000]) {
        final note = usage(used).note.toLowerCase();
        expect(note, isNot(contains('!')));
        expect(note, isNot(contains('estour')));
        expect(note, isNot(contains('cuidado')));
        expect(note, isNot(contains('gast')));
      }
    });

    test('quem passou do limite tem zero livre, nunca livre negativo', () {
      expect(usage(124000).freeCents, 76000);
      expect(usage(220000).freeCents, 0);
      expect(usage(124000).percent, 62);
    });
  });

  group('CajuiCreditCard3D', () {
    testWidgets('RNF-A11Y-06 um toque vira o cartão e o leitor ouve o verso', (
      tester,
    ) async {
      final flips = <bool>[];
      await tester.pumpWidget(_card(onFlip: flips.add));

      expect(find.bySemanticsLabel(_front), findsOneWidget);
      await tester.tap(find.byType(CajuiCreditCard3D));
      await tester.pumpAndSettle();

      expect(flips, [true]);
      expect(
        find.bySemanticsLabel(
          'Limite do Cartão Ipê: em uso ${_rs}1.240,00, livre ${_rs}760,00, '
          '62% do limite. Metade do limite já está em uso. Toque para voltar.',
        ),
        findsOneWidget,
      );
      // Os lados escondidos que dão a altura não se tocam: só o visível conta.
      expect(
        find
            .text('62% do limite · Metade do limite já está em uso')
            .hitTestable(),
        findsOneWidget,
      );
    });

    testWidgets('com movimento, o arrasto de lado inclina o cartão', (
      tester,
    ) async {
      await tester.pumpWidget(_card());
      await _drag(tester, const Offset(20, 0));

      final (side, _) = _lean(tester);
      expect(side.abs(), greaterThan(0.05));
      expect(find.byType(AnimatedSwitcher), findsNothing);
      // Arrastar não é tocar: o cartão continua de frente.
      expect(find.bySemanticsLabel(_front), findsOneWidget);
    });

    testWidgets('RNF-A11Y-10 o arrasto de cima para baixo é da rolagem', (
      tester,
    ) async {
      await tester.pumpWidget(_card(scrolling: true));
      await _drag(tester, const Offset(0, 20));

      final (side, front) = _lean(tester);
      expect(side, 0);
      expect(front, 0);
    });

    testWidgets('RNF-A11Y-07 no reduzido: reto, parado, e virar é fusão', (
      tester,
    ) async {
      await tester.pumpWidget(_card(theme: reduced));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(CajuiCreditCard3D)),
      );
      for (var i = 0; i < 4; i++) {
        await gesture.moveBy(const Offset(20, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(tester.hasRunningAnimations, isFalse);
      expect(find.byType(AnimatedSwitcher), findsOneWidget);
      await gesture.up();
      await tester.tap(find.byType(CajuiCreditCard3D));
      await tester.pumpAndSettle();
      expect(find.text('Em uso').hitTestable(), findsOneWidget);
    });

    testWidgets('RNF-A11Y-04 com fonte a 200% os dois lados cabem', (
      tester,
    ) async {
      await tester.pumpWidget(_card(textScale: 2, used: 170000));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(CajuiCreditCard3D));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Em uso').hitTestable(), findsOneWidget);
    });

    testWidgets('RNF-A11Y-05 o cartão é alvo de toque de sobra', (
      tester,
    ) async {
      await tester.pumpWidget(_card());

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  });
}
