import 'package:cajui/src/features/ledger/presentation/sync_on_resume.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_uplink.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/test_scope.dart';

/// Sobe a casca com a subida de mentira, com ou sem sessão aberta.
Future<FakeUplink> _open(WidgetTester tester, {required bool sessao}) async {
  final uplink = FakeUplink()..session = sessao;
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(journal: MemoryLedgerJournal(), uplink: uplink),
      child: const SyncOnResume(child: SizedBox.shrink()),
    ),
  );
  await tester.pump();
  return uplink;
}

Future<void> _voltaAoApp(WidgetTester tester) async {
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
  tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('abrir o app também tenta: o arranque não é uma volta, e o '
      'ouvinte de ciclo de vida não dispara nele', (tester) async {
    final uplink = await _open(tester, sessao: true);

    await tester.pumpAndSettle();

    expect(uplink.categories, isNotEmpty);
  });

  testWidgets('RN-781 · voltar ao app tenta subir o que ficou para trás', (
    tester,
  ) async {
    final uplink = await _open(tester, sessao: true);

    await _voltaAoApp(tester);

    // As categorias vão na frente de tudo numa subida: vê-las lá é a prova
    // de que ela aconteceu, sem ninguém ter tocado em nada.
    expect(uplink.categories, isNotEmpty);
  });

  testWidgets('sem sessão aberta, voltar ao app não fala com o servidor: '
      'a digital não se pede por voltar a uma tela', (tester) async {
    final uplink = await _open(tester, sessao: false);

    await _voltaAoApp(tester);

    expect(uplink.categories, isEmpty);
    expect(uplink.calls, isEmpty);
  });
}
