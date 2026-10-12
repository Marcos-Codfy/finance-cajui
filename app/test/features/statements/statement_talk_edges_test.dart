import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:cajui/src/features/statements/presentation/statement_talk_state.dart';
import 'package:cajui/src/features/statements/presentation/statement_talk_view_model.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_page_source.dart';
import '../../support/statement_phone.dart';

CardDefined _card(String id, String name) => CardDefined(
  id: 'fact-$id',
  card: CreditCard.create(
    id: id,
    name: name,
    closingDay: 25,
    dueDay: 5,
  ).valueOrNull!,
);

/// Setembro com a Loja Estrela no cartão.
final List<StatementMovement> _onCard = [
  for (final movement in septemberMovements) _paidByCard(movement),
];

StatementMovement _paidByCard(StatementMovement movement) =>
    movement.description != 'Loja Estrela'
    ? movement
    : StatementMovement(
        sourceLine: movement.sourceLine,
        day: movement.day,
        month: movement.month,
        description: movement.description,
        amount: movement.amount,
        categoryId: movement.categoryId,
        paymentKind: PaymentMethodKind.creditCard,
      );

void main() {
  testWidgets('RN-1101 · o segundo extrato espera o primeiro fechar e '
      'abre depois, sem se perder', (tester) async {
    final phone = await openStatementPhone(tester);
    await phone.share(tester, 'extrato-1');
    await phone.share(tester, 'extrato-2');

    final first = phone.container.read(statementTalkProvider);
    expect((first as StatementTalkOpen).capture!.source.id, 'extrato-1');

    await chooseInStatement(tester, 'Conferir depois');

    final second = phone.container.read(statementTalkProvider);
    expect((second as StatementTalkOpen).capture!.source.id, 'extrato-2');
    expect(find.textContaining('Li 5 movimentações'), findsOneWidget);
    final pending = await phone.container.read(pendingCapturesProvider.future);
    expect(pending.map((item) => item.id).toSet(), {'extrato-1', 'extrato-2'});
  });

  testWidgets('E-AI-02 · a leitura que para fala pelo catálogo, sem '
      'marcador por preencher, e "Tentar de novo" lê outra vez', (
    tester,
  ) async {
    final phone = await openStatementPhone(
      tester,
      pages: FakePageSource({
        1: [
          pageFailed(ErrorCode.ai02),
          pageRead(
            movements: septemberMovements,
            period: const BudgetMonth(2026, 9),
          ),
        ],
      }),
    );
    await phone.share(tester, 'extrato-1');

    expect(
      phone.container.read(statementTalkProvider),
      isA<StatementTalkFailed>(),
    );
    expect(find.textContaining('{'), findsNothing);
    expect(find.textContaining('}'), findsNothing);

    await chooseInStatement(tester, 'Tentar de novo');

    expect(find.textContaining('Li 5 movimentações'), findsOneWidget);
    expect(phone.book.entries, isEmpty);
  });

  testWidgets('RN-1114 · com dois cartões, a Juju pergunta qual antes dos '
      'blocos, e a compra no cartão vai para o escolhido', (tester) async {
    final phone = await openStatementPhone(
      tester,
      pages: septemberSource(_onCard),
      events: [_card('roxo', 'Cartão Roxo'), _card('azul', 'Cartão Azul')],
    );
    await phone.share(tester, 'extrato-1');

    expect(find.textContaining(StatementWords.whichCard), findsOneWidget);
    await chooseInStatement(tester, 'Cartão Azul');
    await talkThroughSeptember(tester);

    final star = phone.book.entries.singleWhere(
      (entry) => entry.description == 'Loja Estrela',
    );
    expect(star.paymentLines.single.paymentMethodId, 'azul');
  });
}
