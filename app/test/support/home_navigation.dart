import 'package:flutter_test/flutter_test.dart';

/// Deixa a animação assentar depois de um toque.
Future<void> settleAfterTap(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

/// Vai à aba Início e abre a porta [label] — "Lançamentos", "Cartões",
/// "Dívidas", "Minhas contas", "Mês a mês" ou o ícone "Ajustes".
///
/// O app abre na conversa (sugestão 3 do dono): tudo o mais começa no
/// Início, e a porta pode estar abaixo da dobra.
Future<void> openFromHome(WidgetTester tester, String label) async {
  await backToTabs(tester);
  await tester.tap(find.bySemanticsLabel('Painel'));
  await settleAfterTap(tester);
  // As portas de menos uso ficam guardadas no "Mais" do Início.
  if (find.bySemanticsLabel(label).evaluate().isEmpty) {
    final more = find.bySemanticsLabel('Mais');
    await tester.ensureVisible(more.first);
    await tester.tap(more.first);
    await settleAfterTap(tester);
  }
  final target = find.bySemanticsLabel(label).first;
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await settleAfterTap(tester);
}

/// Volta pelas telas empilhadas até a barra das abas aparecer de novo: a
/// tela empilhada esconde a barra, e o `find` não enxerga o que está fora
/// de cena.
Future<void> backToTabs(WidgetTester tester) async {
  final tabs = find.bySemanticsLabel('Painel');
  for (var depth = 0; depth < 6 && tabs.evaluate().isEmpty; depth++) {
    final back = find.bySemanticsLabel('Voltar');
    if (back.evaluate().isEmpty) return;
    await tester.tap(back.last);
    await settleAfterTap(tester);
  }
}
