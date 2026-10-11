import 'package:cajui/src/features/ledger/application/entry_draft.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/notifications/application/notice_announcement.dart';
import 'package:cajui/src/features/notifications/application/notification_providers.dart';
import 'package:cajui/src/features/notifications/application/queued_notice.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_scope.dart';
import 'fake_notice_device.dart';

/// A fila das notificações do banco tratada de ponta a ponta, com o livro de
/// verdade e o lado nativo de mentira. Textos e valores fictícios.
void main() {
  late FakeNoticeDevice device;
  late ProviderContainer container;

  const nubankPurchase =
      r'Compra de R$ 45,90 APROVADA em MERCADO BOM PRECO para o cartão com '
      'final 1234.';

  setUp(() {
    device = FakeNoticeDevice();
    container = ProviderContainer(
      overrides: [
        ...testOverrides(),
        bankNoticeDeviceProvider.overrideWithValue(device),
      ],
    );
  });
  tearDown(() => container.dispose());

  Future<LedgerBook> drain() async {
    await container.read(bankNoticeServiceProvider).drain();
    return await container.read(ledgerProvider.future);
  }

  Future<void> card(String name) => container
      .read(ledgerProvider.notifier)
      .defineCard(name: name, closingDay: 1, dueDay: 8);

  String methodOf(LedgerBook book, Entry entry) =>
      book.methodOf(entry.paymentLines.single.paymentMethodId).name;

  test('RN-786 · a compra no cartão do banco que avisou entra sozinha, com '
      'origem "notificação", e o aviso oferece Desfazer', () async {
    await card('Roxinho');
    device.push(bankNotice('n1', BankApp.nubank, nubankPurchase));

    final book = await drain();

    final entry = book.entries.single;
    expect(entry.id, 'notice-n1');
    expect(entry.origin, EntryOrigin.notification);
    expect(entry.amount, const Money.fromCents(4590));
    expect(entry.occurredOn, testToday);
    expect(entry.description, 'Mercado Bom Preco');
    expect(entry.categoryId, 'groceries', reason: 'o ramo vem do nome');
    expect(methodOf(book, entry), 'Roxinho');
    expect(device.acked, ['n1']);
    final said = device.announced.single as RecordedAnnouncement;
    expect(said.entryId, 'notice-n1');
    expect(
      said.title,
      'Lancei ${MoneyFormat.brl(const Money.fromCents(4590))} em '
      'Mercado Bom Preco',
    );
    expect(said.text, startsWith('Mercado · Roxinho.'));
  });

  test('RN-789 · a mesma notificação duas vezes lança uma vez só', () async {
    await card('Roxinho');
    device.push(bankNotice('n1', BankApp.nubank, nubankPurchase));
    await drain();
    device.push(bankNotice('n1', BankApp.nubank, nubankPurchase));

    final book = await drain();

    expect(book.entries, hasLength(1));
    expect(device.announced, hasLength(1));
    expect(device.acked, ['n1', 'n1']);
  });

  test('RN-786 · Desfazer cancela, e a notificação repetida depois não lança '
      'de novo', () async {
    await card('Roxinho');
    device.push(bankNotice('n1', BankApp.nubank, nubankPurchase));
    await drain();
    device.push(const UndoNotice(id: 'undo-notice-n1', entryId: 'notice-n1'));
    expect((await drain()).entries, isEmpty);

    device.push(bankNotice('n1', BankApp.nubank, nubankPurchase));

    expect((await drain()).entries, isEmpty);
    expect(device.announced, hasLength(1), reason: 'só o primeiro aviso');
  });

  test('RN-786 · Pix enviado entra no Pix; sem palpite de categoria, fica '
      'em Outros, para a revisão de domingo', () async {
    device.push(
      bankNotice(
        'p1',
        BankApp.inter,
        r'Pix enviado com sucesso: R$ 75,00 para Beltrano Silva',
      ),
    );

    final book = await drain();

    final entry = book.entries.single;
    expect(methodOf(book, entry), 'Pix');
    expect(entry.categoryId, 'other');
    expect(entry.description, 'Beltrano Silva');
    final said = device.announced.single as RecordedAnnouncement;
    expect(
      said.title,
      'Lancei ${MoneyFormat.brl(const Money.fromCents(7500))} para '
      'Beltrano Silva',
    );
    expect(said.text, startsWith('Outros · Pix.'));
  });

  test('RN-789 · débito vai para Débito, boleto para Boleto', () async {
    device
      ..push(
        bankNotice(
          'd1',
          BankApp.nubank,
          r'Compra de R$ 12,50 no débito APROVADA em PADARIA SOL NASCENTE.',
        ),
      )
      ..push(
        bankNotice(
          'b1',
          BankApp.inter,
          r'Pagamento de boleto realizado: R$ 210,35',
        ),
      );

    final book = await drain();

    expect(book.entries.map((entry) => methodOf(book, entry)), [
      'Débito',
      'Boleto',
    ]);
    expect(book.entries.first.categoryId, 'bakery');
    expect(book.entries.last.description, 'Boleto');
    final titles = [for (final said in device.announced) said.title];
    expect(titles.last, startsWith('Lancei o boleto de'));
  });

  test('RN-789 · o que já está no livro, com o mesmo valor no mesmo dia, '
      'não lança de novo nem avisa', () async {
    await card('Roxinho');
    final book = await container.read(ledgerProvider.future);
    await container
        .read(ledgerProvider.notifier)
        .record(
          EntryDraft(
            occurredOn: testToday,
            amountCents: 4590,
            description: 'Mercado',
            method: book.methodOf('pix'),
          ),
        );
    device.push(bankNotice('n1', BankApp.nubank, nubankPurchase));

    final after = await drain();

    expect(after.entries, hasLength(1));
    expect(device.announced, isEmpty);
    expect(device.acked, ['n1']);
  });

  test('RN-787 · o que não é movimentação não lança, não avisa e sai da '
      'fila', () async {
    device.push(
      bankNotice('f1', BankApp.nubank, r'A fatura fechou em R$ 1.234,56.'),
    );

    final book = await drain();

    expect(book.entries, isEmpty);
    expect(device.announced, isEmpty);
    expect(device.acked, ['f1']);
  });

  test('o app que abre pede para parar: a rodada não trata mais nada, e o '
      'resto fica na fila', () async {
    device
      ..stop = true
      ..push(bankNotice('n1', BankApp.nubank, nubankPurchase));

    await drain();

    expect(device.acked, isEmpty);
    expect(device.queue, hasLength(1));
  });
}
