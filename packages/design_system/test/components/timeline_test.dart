import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

void main() {
  testWidgets('a linha do tempo mostra cada item com a frase dele, e a marca '
      'de quem venceu ganha o tom de falta', (tester) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 360,
          child: CajuiTimeline(
            items: [
              CajuiTimelineItem(
                title: 'Aluguel',
                subtitle: 'vence dia 5 · paga',
                cents: 100000,
                mark: CajuiTimelineMark.done,
              ),
              CajuiTimelineItem(
                title: 'Luz',
                subtitle: 'venceu dia 10 · a pagar',
                cents: 18000,
                mark: CajuiTimelineMark.late,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Aluguel'), findsOneWidget);
    expect(find.text('venceu dia 10 · a pagar'), findsOneWidget);
    final late = CajuiThemeData.light().colors.shortfall;
    final dots = tester
        .widgetList<Container>(find.byType(Container))
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .where((box) => box.shape == BoxShape.circle);
    expect(dots.map((dot) => dot.color), contains(late));
  });
}
