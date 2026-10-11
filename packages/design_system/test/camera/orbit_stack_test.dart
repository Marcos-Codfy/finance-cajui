import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

/// Uma aba com estado: conta os toques.
class _Counter extends StatefulWidget {
  const new(this.name);

  final String name;

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => setState(() => _taps++),
    child: SizedBox.expand(child: Text('${widget.name} $_taps')),
  );
}

Widget _tabs(int index, {CajuiThemeData? theme}) => host(
  SizedBox(
    width: 400,
    height: 600,
    child: CajuiOrbitStack(
      index: index,
      children: const [_Counter('conversa'), _Counter('inicio')],
    ),
  ),
  theme: theme,
);

void main() {
  group('CajuiOrbitStack · trocar de aba é a câmera orbitar', () {
    testWidgets('as abas guardam o estado na ida e na volta', (tester) async {
      await tester.pumpWidget(_tabs(0));
      await tester.tap(find.text('conversa 0'));
      await tester.pump();

      await tester.pumpWidget(_tabs(1));
      await tester.pumpAndSettle();
      await tester.pumpWidget(_tabs(0));
      await tester.pumpAndSettle();

      expect(find.text('conversa 1'), findsOneWidget);
    });

    testWidgets('no meio da órbita as duas aparecem, giradas; ao fim, só a '
        'da frente, plana', (tester) async {
      await tester.pumpWidget(_tabs(0));
      await tester.pumpWidget(_tabs(1));
      await tester.pump(CajuiDurations.slow ~/ 2);

      expect(find.text('conversa 0'), findsOneWidget);
      expect(find.text('inicio 0'), findsOneWidget);
      final posed = tester.widgetList<CajuiPosed>(find.byType(CajuiPosed));
      expect(posed.where((it) => it.pose.turn != 0), hasLength(2));

      await tester.pumpAndSettle();
      expect(find.text('conversa 0'), findsNothing);
      expect(
        tester
            .widgetList<CajuiPosed>(find.byType(CajuiPosed))
            .every((it) => it.pose.isFlat),
        isTrue,
      );
    });

    testWidgets('só a aba da frente recebe o toque, mesmo durante a órbita', (
      tester,
    ) async {
      await tester.pumpWidget(_tabs(0));
      await tester.pumpWidget(_tabs(1));
      await tester.pump(CajuiDurations.slow ~/ 2);

      await tester.tapAt(const Offset(400, 300));
      await tester.pumpAndSettle();

      expect(find.text('inicio 1'), findsOneWidget);
      await tester.pumpWidget(_tabs(0));
      await tester.pumpAndSettle();
      expect(find.text('conversa 0'), findsOneWidget);
    });

    testWidgets('RNF-A11Y-07 · movimento reduzido: troca em esmaecer curto, '
        'sem giro', (tester) async {
      final reduced = CajuiThemeData.light(motionLevel: MotionLevel.reduced);
      await tester.pumpWidget(_tabs(0, theme: reduced));
      await tester.pumpWidget(_tabs(1, theme: reduced));
      await tester.pump(CajuiDurations.reducedFade ~/ 2);

      expect(
        tester
            .widgetList<CajuiPosed>(find.byType(CajuiPosed))
            .every((it) => it.pose.isFlat),
        isTrue,
      );
      await tester.pump(CajuiDurations.reducedFade);
      expect(find.text('conversa 0'), findsNothing);
    });

    testWidgets('a aba que sai perde o foco: o teclado não escreve nela', (
      tester,
    ) async {
      final field = FocusNode();
      addTearDown(field.dispose);
      Widget tabs(int index) => host(
        SizedBox(
          width: 400,
          height: 600,
          child: CajuiOrbitStack(
            index: index,
            children: [
              Focus(focusNode: field, child: const SizedBox.expand()),
              const _Counter('inicio'),
            ],
          ),
        ),
      );
      await tester.pumpWidget(tabs(0));
      field.requestFocus();
      await tester.pump();
      expect(field.hasFocus, isTrue);

      await tester.pumpWidget(tabs(1));
      await tester.pumpAndSettle();

      expect(field.hasFocus, isFalse);
    });
  });
}
