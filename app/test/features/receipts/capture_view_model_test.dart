import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/receipts/application/capture_draft.dart';
import 'package:cajui/src/features/receipts/application/read_outcome.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:cajui/src/features/receipts/application/shared_item.dart';
import 'package:cajui/src/features/receipts/presentation/capture_state.dart';
import 'package:cajui/src/features/receipts/presentation/capture_view_model.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_inbox.dart';
import '../../support/fake_reader.dart';
import '../../support/pix_receipt.dart';
import '../../support/test_scope.dart';

const _pix = SharedText(id: 'c1', text: pixReceiptText);

void main() {
  late FakeInbox inbox;
  late ProviderContainer container;
  late List<CaptureState> seen;

  CaptureViewModel capture() => container.read(captureProvider.notifier);
  CaptureState state() => container.read(captureProvider);
  CaptureReady ready() => state() as CaptureReady;

  /// Faz [items] chegarem e espera a fila andar até parar.
  Future<void> share(List<SharedItem> items) async {
    inbox.share(items);
    await pumpEventQueue();
  }

  /// Lança o comprovante em conferência na categoria [categoryId].
  Future<Entry> confirmAs(String categoryId) async {
    final book = await container.read(ledgerProvider.future);
    final draft = CaptureDraft.of(
      ready().capture,
      book: book,
      today: testToday,
    ).copyWith(category: book.categoryOf(categoryId));
    final entry = (await container.read(ledgerProvider.notifier).record(draft))
        .valueOrNull!;
    await capture().confirmed(ready().capture, entry);
    return entry;
  }

  setUp(() {
    inbox = FakeInbox();
    seen = [];
    container = ProviderContainer(
      overrides: testOverrides(
        inbox: inbox,
        reader: FakeReader({
          '/inbox/dark': const ReadFailed(ErrorCode.capt01),
          '/inbox/pdf': const ReadText(pixReceiptText),
        }),
      ),
    );
    addTearDown(container.dispose);
    container.listen(captureProvider, (_, next) => seen.add(next));
  });

  test('RN-780 · Pix compartilhado vira proposta sem rede nenhuma', () async {
    await share(const [_pix]);
    final proposal = ready().capture.proposal;
    final draft = CaptureDraft.of(
      ready().capture,
      book: DefaultCatalog.emptyBook,
      today: testToday,
    );

    expect(proposal.amount.value, const Money.fromCents(600));
    expect(proposal.occurredOn.value, LocalDate(2026, 9, 12));
    expect(draft.description, 'LANCHONETE E RESTAURANTE SABOR DA PRACA');
    expect(draft.method?.kind, PaymentMethodKind.pix);
    expect(draft.category, isNull, reason: 'RN-782: sem palpite de categoria');
    expect(draft.origin, EntryOrigin.share);
  });

  test('RN-705 · vários de uma vez: um por vez, na ordem recebida', () async {
    await share(const [_pix, SharedText(id: 'c2', text: 'PADARIA 8,50')]);

    expect(ready().capture.source.id, 'c1');
    expect(state().waiting, 1);

    await capture().defer(ready().capture);

    expect(ready().capture.source.id, 'c2');
    expect(state().waiting, 0);
  });

  test('E-CAPT-03 · arquivo grande demais diz o tamanho', () async {
    await share(const [
      RejectedShare(
        id: 'big',
        code: ErrorCode.capt03,
        detail: {'sizeBytes': 22 * 1024 * 1024},
      ),
    ]);

    final failed = state() as CaptureFailed;
    expect(failed.error.code, ErrorCode.capt03);
    expect(failed.error.text.message, contains('22 MB'));
  });

  test('E-CAPT-01 · imagem sem texto legível, e texto vazio', () async {
    await share(const [SharedFile(id: 'd', path: '/inbox/dark', isPdf: false)]);
    expect((state() as CaptureFailed).error.code, ErrorCode.capt01);

    await capture().dismiss();
    await share(const [SharedText(id: 'e', text: '   ')]);
    expect((state() as CaptureFailed).error.code, ErrorCode.capt01);
  });

  test(
    'RNF-PERF-06 · em PDF, a tela recebe o progresso real da leitura',
    () async {
      await share(const [SharedFile(id: 'p', path: '/inbox/pdf', isPdf: true)]);

      final reading = seen.whereType<CaptureReading>().last;
      expect((reading.page, reading.of), (1, 2));
      expect(state(), isA<CaptureReady>());
    },
  );

  test(
    'RN-721 · "Conferir depois" guarda, e reabrir refaz a proposta',
    () async {
      await share(const [_pix]);
      await capture().defer(ready().capture);

      final pending = await container.read(captureShelfProvider).pending();
      expect(state(), isA<CaptureIdle>());
      expect(pending.single.id, 'c1');

      await capture().reopen(pending.single);
      expect(ready().capture.proposal.amount.value?.cents, 600);
    },
  );

  test('RN-763 · a categoria escolhida é aprendida, e o mesmo lugar chega '
      'com confiança alta na vez seguinte', () async {
    await share(const [_pix]);
    await confirmAs('eating-out');

    await share(const [SharedText(id: 'c9', text: pixReceiptText)]);

    final category = ready().capture.proposal.category;
    expect(category.value, 'eating-out');
    expect(category.source, FieldSource.learnedRule);
    expect(category.confidence, Confidence.high);
  });

  test(
    'RN-781 · confirmar o mesmo comprovante duas vezes grava um fato só',
    () async {
      await share(const [_pix]);
      final captured = ready().capture;
      final first = await confirmAs('eating-out');

      await capture().reopen(captured.source);
      final second = await confirmAs('eating-out');
      final book = await container.read(ledgerProvider.future);

      expect(second.id, first.id);
      expect(book.entries, hasLength(1));
      expect(await container.read(captureShelfProvider).pending(), isEmpty);
    },
  );

  test('RN-723 · descartar apaga o arquivo local e não lança nada', () async {
    await share(const [SharedFile(id: 'p', path: '/inbox/pdf', isPdf: true)]);

    await capture().discard(ready().capture);
    final book = await container.read(ledgerProvider.future);

    expect(inbox.discarded, ['/inbox/pdf']);
    expect(book.entries, isEmpty);
    expect(state(), isA<CaptureIdle>());
  });
}
