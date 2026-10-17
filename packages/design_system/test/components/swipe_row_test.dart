import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

void main() {
  testWidgets('para a direita chama a ação e a linha volta; para a esquerda '
      'a linha sai e avisa', (tester) async {
    var started = 0;
    var ended = 0;
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 320,
          child: CajuiSwipeRow(
            id: 'mercado',
            startLabel: 'Corrigir',
            onStart: () => started++,
            endLabel: 'Cancelar',
            onEnd: () => ended++,
            child: const SizedBox(height: 56, child: Text('Mercado')),
          ),
        ),
      ),
    );

    await tester.drag(find.text('Mercado'), const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(started, 1);
    expect(find.text('Mercado'), findsOneWidget);

    await tester.drag(find.text('Mercado'), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(ended, 1);
  });
}
