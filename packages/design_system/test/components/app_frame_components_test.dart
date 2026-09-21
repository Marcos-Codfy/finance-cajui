import 'dart:ui' show Tristate;

import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

const _destinations = [
  CajuiNavDestination(icon: CajuiIconData.chart, label: 'Painel'),
  CajuiNavDestination(icon: CajuiIconData.receipt, label: 'Lançamentos'),
  CajuiNavDestination(icon: CajuiIconData.sliders, label: 'Ajustes'),
];

void main() {
  group('CajuiNavBar', () {
    testWidgets('mostra o nome de cada destino e avisa qual foi tocado', (
      tester,
    ) async {
      final selected = <int>[];
      await tester.pumpWidget(
        host(
          CajuiNavBar(
            destinations: _destinations,
            selectedIndex: 0,
            onSelected: selected.add,
          ),
        ),
      );

      await tester.tap(find.text('Ajustes'));

      expect(find.text('Painel'), findsOneWidget);
      expect(find.text('Lançamentos'), findsOneWidget);
      expect(selected, [2]);
    });

    testWidgets('diz ao leitor de tela qual destino está em vigor', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          CajuiNavBar(
            destinations: _destinations,
            selectedIndex: 1,
            onSelected: (_) {},
          ),
        ),
      );

      final current = tester.getSemantics(find.bySemanticsLabel('Lançamentos'));
      final other = tester.getSemantics(find.bySemanticsLabel('Painel'));

      // Destino é "selecionado", não "ligado": ele não desliga sozinho.
      expect(current.flagsCollection.isSelected, Tristate.isTrue);
      expect(other.flagsCollection.isSelected, Tristate.isFalse);
      expect(current.flagsCollection.isToggled, Tristate.none);
      handle.dispose();
    });

    testWidgets('cabe em 320 px com a fonte ampliada em 200%', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: CajuiNavBar(
              destinations: _destinations,
              selectedIndex: 0,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('CajuiScreen', () {
    testWidgets('o título é cabeçalho para o leitor de tela', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const CajuiScreen(title: 'Lançamentos', children: [])),
      );

      final title = tester.getSemantics(find.text('Lançamentos'));

      expect(title.flagsCollection.isHeader, isTrue);
      handle.dispose();
    });

    testWidgets('só mostra o voltar quando há para onde voltar', (
      tester,
    ) async {
      var back = 0;
      await tester.pumpWidget(
        host(
          CajuiScreen(title: 'Nova', onBack: () => back++, children: const []),
        ),
      );

      await tester.tap(find.bySemanticsLabel('Voltar'));

      expect(back, 1);
    });

    testWidgets('a ação do pé fica à vista sem rolar', (tester) async {
      await tester.pumpWidget(
        host(
          CajuiScreen(
            title: 'Nova despesa',
            footer: CajuiButton(label: 'Lançar', onPressed: () {}),
            children: [for (var i = 0; i < 40; i++) Text('linha $i')],
          ),
        ),
      );

      expect(find.text('Lançar').hitTestable(), findsOneWidget);
    });
  });

  group('CajuiAppSurface', () {
    testWidgets('segue o tema do aparelho e o pedido de menos movimento', (
      tester,
    ) async {
      late CajuiThemeData theme;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            platformBrightness: Brightness.dark,
            disableAnimations: true,
          ),
          child: Builder(
            builder: (context) {
              theme = CajuiAppSurface.themeOf(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(theme.colors.brightness, Brightness.dark);
      expect(theme.motionLevel, MotionLevel.reduced);
    });

    testWidgets('aparelho que perde quadros baixa um nível de movimento', (
      tester,
    ) async {
      late CajuiThemeData theme;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Builder(
            builder: (context) {
              theme = CajuiAppSurface.themeOf(context, framesAreDropping: true);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(theme.colors.brightness, Brightness.light);
      expect(theme.motionLevel, MotionLevel.lite);
    });
  });

  group('CajuiSectionTitle', () {
    testWidgets('é cabeçalho para o leitor de tela, e traz o próprio respiro', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const CajuiSectionTitle('Contas fixas')));

      expect(
        tester.getSemantics(find.text('Contas fixas')),
        isSemantics(label: 'Contas fixas', isHeader: true),
      );
      final padding = tester.widget<Padding>(
        find
            .ancestor(
              of: find.text('Contas fixas'),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(
        padding.padding,
        const EdgeInsets.only(
          top: CajuiSpacing.section,
          bottom: CajuiSpacing.sm,
        ),
      );
      handle.dispose();
    });
  });
}
