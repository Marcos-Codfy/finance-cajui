import 'dart:typed_data';

import 'package:api_contract/api_contract.dart';
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
import '../../support/test_scope.dart';

/// Uma foto qualquer, com a assinatura de JPEG.
final Uint8List _photo = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3]);

/// Um classificador que devolve sempre a mesma proposta: o que a IA teria
/// lido da foto.
final class _ReadsThePhoto implements ReceiptClassifier {
  const new(this.amount);

  final Money? amount;

  @override
  Future<EntryProposal> classify(ClassificationRequest request) async =>
      EntryProposal(
        documentKind: const ProposedField.resolved(
          DocumentKind.purchase,
          source: FieldSource.ai,
        ),
        amount: amount == null || !request.hasImages
            ? const ProposedField.unread()
            : ProposedField.resolved(amount!, source: FieldSource.ai),
        occurredOn: const ProposedField.unread(),
        category: const ProposedField.unread(),
        paymentKind: const ProposedField.unread(),
        description: 'Mercadinho do Zé',
      );
}

void main() {
  group('ADR-022 · foto que o celular não conseguiu ler', () {
    Future<CaptureState> arrive(ReceiptClassifier classifier) async {
      final inbox = FakeInbox();
      final container = ProviderContainer(
        overrides: [
          ...testOverrides(
            inbox: inbox,
            reader: FakeReader({
              '/inbox/escura': ReadText('', images: [_photo]),
            }),
          ),
          receiptClassifierProvider.overrideWithValue(classifier),
        ],
      );
      addTearDown(container.dispose);
      container.read(captureProvider);
      inbox.share(const [
        SharedFile(id: 'c1', path: '/inbox/escura', isPdf: false),
      ]);
      await pumpEventQueue();
      final settled = container.read(captureProvider);
      return settled;
    }

    test('a IA leu o valor: a conferência abre, preenchida', () async {
      final state = await arrive(const _ReadsThePhoto(Money.fromCents(2390)));

      expect(state, isA<CaptureReady>());
      final proposal = (state as CaptureReady).capture.proposal;
      expect(proposal.amount.value, const Money.fromCents(2390));
      expect(proposal.displayDescription, 'Mercadinho do Zé');
    });

    test('adiar e reabrir: o arquivo é lido de novo, e a IA vê a foto outra '
        'vez', () async {
      final inbox = FakeInbox();
      final container = ProviderContainer(
        overrides: [
          ...testOverrides(
            inbox: inbox,
            reader: FakeReader({
              '/inbox/escura': ReadText('', images: [_photo]),
            }),
          ),
          receiptClassifierProvider.overrideWithValue(
            const _ReadsThePhoto(Money.fromCents(2390)),
          ),
        ],
      );
      addTearDown(container.dispose);
      final capture = container.read(captureProvider.notifier);
      inbox.share(const [
        SharedFile(id: 'c1', path: '/inbox/escura', isPdf: false),
      ]);
      await pumpEventQueue();
      final first = container.read(captureProvider) as CaptureReady;

      await capture.defer(first.capture);
      final pending = await container.read(pendingCapturesProvider.future);
      await capture.reopen(pending.single);

      final again = container.read(captureProvider) as CaptureReady;
      expect(again.capture.proposal.amount.value, const Money.fromCents(2390));
    });

    test('texto curto compartilhado é texto, e não foto escura: abre a '
        'conferência', () async {
      final inbox = FakeInbox();
      final container = ProviderContainer(
        overrides: testOverrides(inbox: inbox),
      );
      addTearDown(container.dispose);
      container.read(captureProvider);
      inbox.share(const [SharedText(id: 't1', text: r'R$ 9,90')]);
      await pumpEventQueue();

      final state = container.read(captureProvider);
      expect(state, isA<CaptureReady>());
      final proposal = (state as CaptureReady).capture.proposal;
      expect(proposal.amount.value, const Money.fromCents(990));
    });

    test('nem o celular nem a IA leram: a saída é a de sempre, outra foto ou '
        'digitar', () async {
      final state = await arrive(const _ReadsThePhoto(null));

      expect(state, isA<CaptureFailed>());
      expect((state as CaptureFailed).error.code, ErrorCode.capt01);
    });
  });
}
