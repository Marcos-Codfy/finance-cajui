import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Uma tela com estado: conta os toques.
class _Screen extends StatefulWidget {
  const new(this.name);

  final String name;

  @override
  State<_Screen> createState() => _ScreenState();
}

class _ScreenState extends State<_Screen> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => setState(() => _taps++),
    child: SizedBox.expand(child: Text('${widget.name} $_taps')),
  );
}

/// Um app com o tema **acima** do navegador, como o Cajui monta: a rota
/// empurrada também precisa dele.
Widget _app({CajuiThemeData? theme}) => WidgetsApp(
  color: const Color(0xFFFBF6EE),
  pageRouteBuilder: <T>(settings, builder) =>
      CajuiPageRoute<T>(settings: settings, builder: builder),
  builder: (context, child) =>
      CajuiTheme(data: theme ?? CajuiThemeData.light(), child: child!),
  home: const _Screen('inicio'),
);

NavigatorState _navigator(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator));

Future<void> _push(WidgetTester tester, String name) {
  _navigator(tester).push(CajuiPageRoute<void>(builder: (_) => _Screen(name)));
  return tester.pump();
}

void main() {
  group('CajuiPageRoute · a troca de tela é a câmera avançando', () {
    testWidgets('no meio da troca a tela nova vem deitada e menor; ao fim, '
        'assenta plana', (tester) async {
      await tester.pumpWidget(_app());
      await _push(tester, 'mes');
      await tester.pump(CajuiDurations.slow ~/ 4);

      final moving = tester.widgetList<CajuiPosed>(find.byType(CajuiPosed));
      expect(moving.any((it) => it.pose.tilt > 0), isTrue);

      await tester.pumpAndSettle();
      final settled = tester.widgetList<CajuiPosed>(
        find.descendant(
          of: find.ancestor(
            of: find.text('mes 0'),
            matching: find.byType(CajuiPosed),
          ),
          matching: find.byType(CajuiPosed),
        ),
      );
      expect(settled.every((it) => it.pose.isFlat), isTrue);
    });

    testWidgets('a tela de trás recua e volta sem perder o estado', (
      tester,
    ) async {
      await tester.pumpWidget(_app());
      await _push(tester, 'mes');
      await tester.pumpAndSettle();
      await tester.tap(find.text('mes 0'));
      await tester.pump();

      await _push(tester, 'detalhe');
      await tester.pumpAndSettle();
      _navigator(tester).pop();
      await tester.pumpAndSettle();

      expect(find.text('mes 1'), findsOneWidget);
    });

    testWidgets('RNF-A11Y-07 · movimento reduzido: só esmaece', (tester) async {
      await tester.pumpWidget(
        _app(theme: CajuiThemeData.light(motionLevel: MotionLevel.reduced)),
      );
      await _push(tester, 'mes');
      await tester.pump(CajuiDurations.slow ~/ 4);

      expect(
        tester
            .widgetList<CajuiPosed>(find.byType(CajuiPosed))
            .every((it) => it.pose.isFlat),
        isTrue,
      );
    });
  });
}
