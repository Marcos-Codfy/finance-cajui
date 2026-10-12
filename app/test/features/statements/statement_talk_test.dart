import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/statement_phone.dart';

void main() {
  testWidgets('RN-1100 e RN-1112 · o extrato compartilhado abre na conversa '
      'da Juju, com o resumo, e fica em "Para conferir" até lançar', (
    tester,
  ) async {
    final phone = await openStatementPhone(tester);
    await phone.share(tester, 'extrato-1');

    expect(
      find.textContaining('Li 5 movimentações de 1 a 10 de setembro.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('1 pagamento de fatura não conta'),
      findsOneWidget,
    );
    expect(find.textContaining('2 ficaram em dúvida'), findsOneWidget);
    expect(find.text('Pode lançar (2)'), findsOneWidget);
    final pending = await phone.container.read(pendingCapturesProvider.future);
    expect(pending.map((item) => item.id), ['extrato-1']);
  });

  testWidgets('RN-1113 a RN-1116 · confere por blocos, pergunta as dúvidas, '
      'lembra as respostas e lança só no fim', (tester) async {
    final phone = await openStatementPhone(tester);
    await phone.share(tester, 'extrato-1');

    expect(find.textContaining('Mercado — 1 compra'), findsOneWidget);
    await chooseInStatement(tester, 'Ver as linhas');
    expect(find.text('01/09 · Assaí Atacadista'), findsOneWidget);
    await chooseInStatement(tester, 'Confere');
    // A marca: "IFD*" é iFood, e cai em Restaurante e lanche sem perguntar.
    expect(
      find.textContaining('Restaurante e lanche — 1 compra'),
      findsOneWidget,
    );
    expect(phone.book.entries, isEmpty, reason: 'nada antes de lançar');

    await chooseInStatement(tester, 'Confere');
    expect(find.textContaining('Pix para Joao P Silva'), findsOneWidget);
    await chooseInStatement(tester, 'Alguém da casa');
    expect(find.textContaining('Loja Estrela'), findsWidgets);
    await chooseInStatement(tester, 'Casa');
    await chooseInStatement(tester, 'Pode lançar (3)');

    expect(phone.book.entries.map((entry) => entry.description).toSet(), {
      'Assaí Atacadista',
      'iFood',
      'Loja Estrela',
    });
    final memory = phone.book.learnedAnswers;
    expect(
      memory.forKey('pessoa:joao p silva')!.treatment,
      LineTreatment.household,
    );
    expect(memory.forKey('loja estrela')!.categoryId, 'home');
    await chooseInStatement(tester, 'Pronto');
    final pending = await phone.container.read(pendingCapturesProvider.future);
    expect(pending, isEmpty, reason: 'lançado e pronto, a captura fecha');
  });

  testWidgets('RN-1117 · ler o mesmo extrato de novo não lança em dobro; o '
      'que já estava é mostrado, e dá para descartar', (tester) async {
    final phone = await openStatementPhone(tester);
    await phone.share(tester, 'extrato-1');
    await talkThroughSeptember(tester);
    await chooseInStatement(tester, 'Pronto');

    await phone.share(tester, 'extrato-2');

    expect(find.textContaining('3 já estavam no Cajui'), findsOneWidget);
    expect(find.textContaining('em dúvida'), findsNothing);
    expect(
      find.textContaining('3 movimentações já estavam no Cajui'),
      findsOneWidget,
    );
    expect(find.text('Pode lançar (0)'), findsOneWidget);
    await chooseInStatement(tester, 'Descartar');
    expect(phone.book.entries, hasLength(3));
    final pending = await phone.container.read(pendingCapturesProvider.future);
    expect(pending, isEmpty, reason: 'descartado, não fica para sempre');
  });

  testWidgets('RN-1119 · desfazer tira os lançamentos e volta à conversa; '
      'lançar de novo grava outra vez, com chaves novas', (tester) async {
    final phone = await openStatementPhone(tester);
    await phone.share(tester, 'extrato-1');
    await talkThroughSeptember(tester);
    final first = {for (final entry in phone.book.entries) entry.id};

    await chooseInStatement(tester, 'Desfazer tudo');
    expect(phone.book.entries, isEmpty);
    expect(find.textContaining('Desfiz os 3 lançamentos'), findsOneWidget);
    final pending = await phone.container.read(pendingCapturesProvider.future);
    expect(pending, isNotEmpty, reason: 'desfeito, volta para conferir');

    await chooseInStatement(tester, 'Pode lançar (3)');

    final again = {for (final entry in phone.book.entries) entry.id};
    expect(again, hasLength(3));
    expect(again.intersection(first), isEmpty);
  });

  testWidgets('"Conferir depois" fecha a conversa sem gravar nada', (
    tester,
  ) async {
    final phone = await openStatementPhone(tester);
    await phone.share(tester, 'extrato-1');

    await chooseInStatement(tester, 'Conferir depois');

    expect(phone.book.entries, isEmpty);
    expect(find.byType(CajuiChatPrompt), findsNothing);
  });
}
