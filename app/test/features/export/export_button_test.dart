import 'dart:async';

import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/budget/presentation/month_page.dart';
import 'package:cajui/src/features/export/application/month_exporter.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/home_navigation.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/test_scope.dart';
import '../review/review_entries.dart';

/// O exportador de mentira: guarda o que recebeu.
final class _Exporter implements MonthExporter {
  final List<MonthExport> received = [];

  @override
  Future<void> export(MonthExport month) async => received.add(month);
}

void main() {
  testWidgets('RN-1090 · "Levar para planilha" no Meu mês entrega o mês '
      'aberto, com os lançamentos dele', (tester) async {
    tester.view.physicalSize = const Size(400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final exporter = _Exporter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...testOverrides(
            journal: MemoryLedgerJournal([
              EntryRecorded(reviewEntry('padaria', categoryId: 'groceries')),
              EntryRecorded(
                reviewEntry('farmacia', categoryId: 'health', daysAgo: 2),
              ),
            ]),
          ),
          monthExporterProvider.overrideWithValue(exporter),
        ],
        child: const CajuiApp(),
      ),
    );
    await tester.pump();
    unawaited(MonthPage.open(tester.element(find.byType(CajuiScreen).first)));
    await settleAfterTap(tester);

    await tester.tap(find.text('Levar para planilha'));
    await settleAfterTap(tester);

    final month = exporter.received.single;
    expect(month.month, testToday.budgetMonth);
    expect(month.rows, hasLength(2));
    expect(month.cashTotal, const Money.fromCents(5000));
  });
}
