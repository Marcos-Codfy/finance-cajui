import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _Opener extends StatelessWidget {
  const new({required this.onPicked});

  final ValueChanged<String?> onPicked;

  @override
  Widget build(BuildContext context) => CajuiButton(
    label: 'Escolher',
    onPressed: () async => onPicked(
      await Navigator.of(context).push<String>(
        CajuiSheetRoute(
          builder: (context) => CajuiSheet(
            title: 'Categoria',
            children: [
              for (final name in ['Mercado', 'Farmácia'])
                CajuiButton(
                  label: name,
                  onPressed: () => Navigator.of(context).pop(name),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Como o app: o tema envolve todas as rotas, e não só a primeira.
Widget _app(Widget home) => WidgetsApp(
  color: const Color(0xFFFFFFFF),
  pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, _, _) => builder(context),
  ),
  builder: (context, child) => CajuiTheme(
    data: CajuiThemeData.light(),
    child: CajuiFeedbackScope(feedback: const SilentFeedback(), child: child!),
  ),
  home: Center(child: home),
);

void main() {
  group('o painel que sobe de baixo', () {
    testWidgets('mostra o título e devolve o que foi tocado', (tester) async {
      String? picked;
      await tester.pumpWidget(_app(_Opener(onPicked: (p) => picked = p)));

      await tester.tap(find.text('Escolher'));
      await tester.pumpAndSettle();
      expect(find.text('Categoria'), findsOneWidget);
      expect(find.text('Escolher'), findsOneWidget, reason: 'a tela de trás');
      await tester.tap(find.text('Farmácia'));
      await tester.pumpAndSettle();

      expect(picked, 'Farmácia');
      expect(find.text('Categoria'), findsNothing);
    });

    testWidgets('tocar fora fecha sem escolher', (tester) async {
      var closed = false;
      await tester.pumpWidget(
        _app(_Opener(onPicked: (p) => closed = p == null)),
      );

      await tester.tap(find.text('Escolher'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(closed, isTrue);
      expect(find.text('Categoria'), findsNothing);
    });
  });
}
