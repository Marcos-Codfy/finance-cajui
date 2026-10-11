import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/notifications/application/notice_announcement.dart';
import 'package:cajui/src/features/notifications/application/notification_providers.dart';
import 'package:cajui/src/features/receipts/application/capture_route.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/test_scope.dart';
import 'fake_notice_device.dart';

/// O que pede um toque em vez de lançar sozinho (RN-788) — e o que o toque
/// abre: o texto entra na conferência de sempre, como compartilhado.
void main() {
  late FakeNoticeDevice device;
  late ProviderContainer container;

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

  Future<void> drain() => container.read(bankNoticeServiceProvider).drain();

  /// O que as regras do comprovante leem do texto que o toque entrega.
  Future<EntryProposal> readShared(String text) =>
      const RuleBasedClassifier().classify(
        ClassificationRequest(
          text: ReceiptText.clean(text),
          categories: DefaultCatalog.categories,
          today: testToday,
          categoryByMerchantKind: DefaultCatalog.categoryByMerchantKind,
        ),
      );

  test('RN-788 · Pix recebido não é lançado: pede um toque, e o toque abre '
      'a tela de recebimento', () async {
    device.push(
      bankNotice(
        'r1',
        BankApp.inter,
        r'Pix recebido: R$ 300,00 de Ciclano Exemplo',
      ),
    );

    await drain();

    expect((await container.read(ledgerProvider.future)).entries, isEmpty);
    final ask = device.announced.single as AskAnnouncement;
    final amount = MoneyFormat.brl(const Money.fromCents(30000));
    expect(ask.title, 'Entrou $amount de Ciclano Exemplo');
    expect(ask.text, 'Toque para registrar na renda do mês.');
    final proposal = await readShared(ask.shareText);
    expect(CaptureRoute.of(proposal), CaptureRoute.income);
    expect(proposal.amount.value, const Money.fromCents(30000));
    expect(proposal.occurredOn.value, testToday);
  });

  test('RN-788 · compra no crédito sem cartão reconhecível pede um toque, e '
      'o toque abre a conferência da compra', () async {
    device.push(
      bankNotice(
        'n1',
        BankApp.nubank,
        r'Compra de R$ 45,90 APROVADA em MERCADO BOM PRECO para o cartão '
            'com final 1234.',
      ),
    );

    await drain();

    expect((await container.read(ledgerProvider.future)).entries, isEmpty);
    final ask = device.announced.single as AskAnnouncement;
    expect(ask.title, endsWith('em Mercado Bom Preco'));
    expect(ask.text, 'Não reconheci o cartão. Toque para registrar.');
    final proposal = await readShared(ask.shareText);
    expect(CaptureRoute.of(proposal), CaptureRoute.expense);
    expect(proposal.amount.value, const Money.fromCents(4590));
    expect(proposal.paymentKind.value, PaymentMethodKind.creditCard);
  });

  test(
    'RN-311 · compra parcelada pede um toque, com as parcelas no texto',
    () async {
      await container
          .read(ledgerProvider.notifier)
          .defineCard(name: 'Roxinho', closingDay: 1, dueDay: 8);
      device.push(
        bankNotice(
          'n2',
          BankApp.nubank,
          r'Compra parcelada de R$ 300,00 em 3x aprovada em LOJA EXEMPLO',
        ),
      );

      await drain();

      final ask = device.announced.single as AskAnnouncement;
      expect(ask.title, startsWith('Compra parcelada de'));
      expect(ask.shareText, contains('Parcelado em 3x'));
      expect((await readShared(ask.shareText)).installments, 3);
    },
  );

  test('a carteira sem cartão reconhecível fica quieta: quem lança é o aviso '
      'do banco, que chega junto — uma vez só', () async {
    await container
        .read(ledgerProvider.notifier)
        .defineCard(name: 'Roxinho', closingDay: 1, dueDay: 8);
    device
      ..push(
        bankNotice(
          'w1',
          BankApp.googleWallet,
          r'R$ 45,90 com Visa •••• 1234',
          title: 'MERCADO BOM PRECO',
        ),
      )
      ..push(
        bankNotice(
          'n1',
          BankApp.nubank,
          r'Compra de R$ 45,90 APROVADA em MERCADO BOM PRECO.',
        ),
      )
      ..push(
        bankNotice(
          'w2',
          BankApp.googleWallet,
          r'R$ 45,90 com Visa •••• 1234',
          title: 'MERCADO BOM PRECO',
        ),
      );

    await drain();

    final book = await container.read(ledgerProvider.future);
    expect(book.entries.single.id, 'notice-n1');
    expect(device.announced, hasLength(1));
    expect(device.acked, ['w1', 'n1', 'w2']);
  });

  test('RN-789 · com o cartão de dígitos no nome, a carteira lança no cartão '
      'certo', () async {
    final ledger = container.read(ledgerProvider.notifier);
    await ledger.defineCard(name: 'Nubank 1234', closingDay: 1, dueDay: 8);
    await ledger.defineCard(name: 'Inter 9876', closingDay: 5, dueDay: 12);
    device.push(
      bankNotice(
        'w1',
        BankApp.googleWallet,
        r'R$ 45,90 com Visa •••• 1234',
        title: 'MERCADO BOM PRECO',
      ),
    );

    await drain();

    final book = await container.read(ledgerProvider.future);
    final line = book.entries.single.paymentLines.single;
    expect(book.methodOf(line.paymentMethodId).name, 'Nubank 1234');
  });
}
