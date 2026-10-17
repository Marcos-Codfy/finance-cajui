import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/host.dart';

const _slices = [
  CajuiRingSlice(
    label: 'Contas fixas',
    cents: 150000,
    color: Color(0xFF5F4E44),
  ),
  CajuiRingSlice(label: 'Assinaturas', cents: 0, color: Color(0xFF8E2F7A)),
  CajuiRingSlice(label: 'Dia a dia', cents: 50000, color: Color(0xFFD5411E)),
];

void main() {
  group('o anel de para onde foi o dinheiro', () {
    testWidgets('a legenda diz nome, valor e parte de cada fatia, e fatia '
        'zerada não aparece', (tester) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 360,
            child: CajuiRingChart(
              slices: _slices,
              total: 200000,
              centerLabel: 'Sai no mês',
            ),
          ),
        ),
      );

      expect(find.text('Contas fixas · 75%'), findsOneWidget);
      expect(find.text('Dia a dia · 25%'), findsOneWidget);
      expect(find.textContaining('Assinaturas'), findsNothing);
      expect(find.text('Sai no mês'), findsOneWidget);
    });

    testWidgets('tocar a legenda, ou a fatia no anel, escolhe', (tester) async {
      final picked = <int>[];
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 360,
            child: CajuiRingChart(
              slices: _slices,
              total: 200000,
              centerLabel: 'Sai no mês',
              onSelected: picked.add,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Dia a dia · 25%'));
      // O alto à direita do anel é o começo: as contas fixas (75%).
      final ring = tester.getTopLeft(find.byType(CustomPaint).first);
      await tester.tapAt(ring + const Offset(170, 60));

      expect(picked, [2, 0]);
    });
  });
}
