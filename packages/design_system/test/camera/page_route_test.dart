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

/// O quanto a tela [name] aparece: o produto das poses acima dela — a de
/// quem recua e a de quem chega. Fora do palco (a rota de baixo, depois que
/// a de cima assentou) ela não é pintada: não aparece.
double _visible(WidgetTester tester, String name) {
  final screen = find.textContaining(name);
  if (screen.evaluate().isEmpty) return 0;
  return tester
      .widgetList<CajuiPosed>(
        find.ancestor(of: screen, matching: find.byType(CajuiPosed)),
      )
      .fold(1, (shown, posed) => shown * posed.pose.opacity);
}

/// Anda a troca até o fim, um quadro de 16 ms por vez, conferindo em cada
/// quadro que as duas telas não estão à vista juntas.
Future<void> _framesWithoutOverlap(WidgetTester tester) async {
  for (var frame = 0; frame < 30; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    final behind = _visible(tester, 'inicio');
    final ahead = _visible(tester, 'mes');
    expect(behind < ahead ? behind : ahead, lessThan(0.05));
  }
  await tester.pumpAndSettle();
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

    testWidgets('quadro a quadro, na ida e na volta, a tela de trás já '
        'sumiu quando a nova aparece', (tester) async {
      await tester.pumpWidget(_app());
      await _push(tester, 'mes');
      await _framesWithoutOverlap(tester);

      _navigator(tester).pop();
      await tester.pump();
      await _framesWithoutOverlap(tester);
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
