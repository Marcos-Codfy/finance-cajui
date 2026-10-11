import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/notifications/application/notice_announcement.dart';
import 'package:cajui/src/features/notifications/application/notification_providers.dart';
import 'package:cajui/src/features/receipts/application/capture_route.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/household_book.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/test_scope.dart';
import 'fake_notice_device.dart';

/// Dinheiro que muda de conta dentro da casa (RN-1072, RN-1073) e a
/// notificação que chega depois do comprovante (RN-1077).
void main() {
  late FakeNoticeDevice device;
  late ProviderContainer container;

  void start(List<LedgerEvent> events) {
    device = FakeNoticeDevice();
    container = ProviderContainer(
      overrides: [
        ...testOverrides(journal: MemoryLedgerJournal(events)),
        bankNoticeDeviceProvider.overrideWithValue(device),
      ],
    );
    addTearDown(container.dispose);
  }

  Future<List<Entry>> drain() async {
    await container.read(bankNoticeServiceProvider).drain();
    return (await container.read(ledgerProvider.future)).entries;
  }

  final brl500 = MoneyFormat.brl(const Money.fromCents(50000));

  test(r'RN-1072 · Pix de R$ 500,00 para MARCOS V M ARRUDA, nome da casa: '
      'não lança, e o aviso diz por quê', () async {
    start([
      householdOf(const [testHouseholdName]),
    ]);
    device.push(
      bankNotice(
        'p1',
        BankApp.inter,
        r'Pix enviado com sucesso: R$ 500,00 para MARCOS V M ARRUDA',
      ),
    );

    final entries = await drain();

    expect(entries, isEmpty);
    final ask = device.announced.single as AskAnnouncement;
    expect(ask.title, 'Pix de $brl500 para Marcos V M Arruda');
    expect(
      ask.text,
      'Entre contas da casa: não entrou como gasto. Se foi gasto, toque '
      'para lançar.',
    );
    final proposal = await const RuleBasedClassifier().classify(
      ClassificationRequest(
        text: ReceiptText.clean(ask.shareText),
        categories: DefaultCatalog.categories,
        today: testToday,
      ),
    );
    expect(CaptureRoute.of(proposal), CaptureRoute.expense);
    expect(proposal.merchant, 'MARCOS V M ARRUDA');
  });

  test('RN-1072 · sem o nome cadastrado, o mesmo Pix lança como sempre '
      '(RN-786)', () async {
    start(const []);
    device.push(
      bankNotice(
        'p1',
        BankApp.inter,
        r'Pix enviado com sucesso: R$ 500,00 para MARCOS V M ARRUDA',
      ),
    );

    final entries = await drain();

    expect(entries.single.amount, const Money.fromCents(50000));
    expect(device.announced.single, isA<RecordedAnnouncement>());
  });

  test('RN-1072 · outro Marcos não é da casa: o Pix para MARCOS SILVA é '
      'gasto', () async {
    start([
      householdOf(const [testHouseholdName]),
    ]);
    device.push(
      bankNotice(
        'p1',
        BankApp.inter,
        r'Pix enviado com sucesso: R$ 500,00 para MARCOS SILVA',
      ),
    );

    final entries = await drain();

    expect(entries.single.description, 'Marcos Silva');
  });

  test('RN-1073 · Pix recebido de alguém da casa não é renda nova: nem '
      'lança, nem pede toque', () async {
    start([
      householdOf(const [testHouseholdName]),
    ]);
    device
      ..push(
        bankNotice(
          'r1',
          BankApp.inter,
          r'Pix recebido: R$ 500,00 de Marcos Arruda',
        ),
      )
      ..push(
        bankNotice(
          'r2',
          BankApp.inter,
          r'Pix recebido: R$ 300,00 de Ciclano Exemplo',
        ),
      );

    final entries = await drain();

    expect(entries, isEmpty);
    final ask = device.announced.single as AskAnnouncement;
    expect(ask.noticeId, 'r2', reason: 'só o de fora da casa pede toque');
    expect(device.acked, ['r1', 'r2']);
  });

  test('RN-1077 · comprovante de ontem para Joana Pereira Lima; a '
      'notificação de hoje para JOANA P LIMA não lança de novo', () async {
    start([
      recordedEntry(
        id: 'c1',
        cents: 15000,
        on: testYesterday,
        description: 'Joana Pereira Lima',
        origin: EntryOrigin.share,
      ),
    ]);
    device.push(
      bankNotice(
        'p1',
        BankApp.inter,
        r'Pix enviado com sucesso: R$ 150,00 para JOANA P LIMA',
      ),
    );

    final entries = await drain();

    expect(entries.map((entry) => entry.id), ['c1']);
    expect(device.announced, isEmpty);
  });

  test(r'RN-1077 · Pix de R$ 50,00 para Lucas Lima avisado ontem e hoje são '
      'dois lançamentos', () async {
    start([
      recordedEntry(
        id: 'notice-ontem',
        cents: 5000,
        on: testYesterday,
        description: 'Lucas Lima',
      ),
    ]);
    device.push(
      bankNotice(
        'p2',
        BankApp.inter,
        r'Pix enviado com sucesso: R$ 50,00 para LUCAS LIMA',
      ),
    );

    final entries = await drain();

    expect(entries.map((entry) => entry.id), ['notice-ontem', 'notice-p2']);
  });
}
