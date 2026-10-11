import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

/// Uma seção com estado: conta os toques.
class _Section extends StatefulWidget {
  const new({super.key});

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => setState(() => _taps++),
    child: SizedBox(height: 80, child: Text('seção $_taps')),
  );
}

Widget _screen({required bool notice, required bool depth}) => host(
  SizedBox(
    width: 400,
    height: 700,
    child: CajuiScreen(
      title: 'Início',
      depth: depth,
      cinematic: true,
      children: [
        if (notice) const SizedBox(height: 40, child: Text('aviso')),
        const _Section(key: ValueKey('numeros')),
      ],
    ),
  ),
);

void main() {
  for (final depth in [true, false]) {
    testWidgets('a seção com chave guarda o estado quando um aviso entra '
        'acima dela (depth: $depth)', (tester) async {
      await tester.pumpWidget(_screen(notice: false, depth: depth));
      await tester.pumpAndSettle();
      await tester.tap(find.text('seção 0'));
      await tester.pump();

      await tester.pumpWidget(_screen(notice: true, depth: depth));
      await tester.pumpAndSettle();

      expect(find.text('aviso'), findsOneWidget);
      expect(find.text('seção 1'), findsOneWidget);
    });
  }
}
