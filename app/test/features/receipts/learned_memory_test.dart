import 'package:cajui/src/features/ledger/application/answer_memory.dart';
import 'package:cajui/src/features/ledger/application/ledger_controller.dart';
import 'package:cajui/src/features/receipts/application/capture.dart';
import 'package:cajui/src/features/receipts/application/capture_draft.dart';
import 'package:cajui/src/features/receipts/application/capture_outcome.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:cajui/src/features/receipts/application/shared_item.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_exchange.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/pix_receipt.dart';
import '../../support/test_scope.dart';
import '../../support/two_phones.dart';

/// Um Pix para uma pessoa, com o nome no rótulo de quem recebeu. Os dados
/// são inventados.
const _pixToPerson = r'''
Comprovante de Pix
Valor: R$ 150,00
Destinatário: João P. Silva
10/09/2026''';

/// Um classificador que guarda cada pedido e responde pelas regras do
/// celular: é o pedido que diria à IA o que o app aprendeu.
final class _Spy implements ReceiptClassifier {
  final List<ClassificationRequest> requests = [];

  @override
  Future<EntryProposal> classify(ClassificationRequest request) {
    requests.add(request);
    return const RuleBasedClassifier().classify(request);
  }
}

/// Um celular sobre [server] com o classificador [spy].
ProviderContainer _phone(FakeExchange server, _Spy spy, String name) {
  final phone = ProviderContainer(
    overrides: [
      ...testOverrides(
        journal: MemoryLedgerJournal(),
        uplink: server,
        downlink: server,
        idPrefix: name,
      ),
      receiptClassifierProvider.overrideWithValue(spy),
    ],
  );
  addTearDown(phone.dispose);
  return phone;
}

Future<Capture> _open(ProviderContainer phone, String id, String text) async {
  final outcome = await phone
      .read(captureServiceProvider)
      .open(SharedText(id: id, text: text));
  return (outcome as CaptureProposed).capture;
}

/// Lança [capture] na categoria [categoryId], como a conferência faz.
Future<void> _confirm(
  ProviderContainer phone,
  Capture capture,
  String categoryId,
) async {
  final book = await phone.read(ledgerProvider.future);
  final draft = CaptureDraft.of(
    capture,
    book: book,
  ).copyWith(category: book.categoryOf(categoryId));
  final entry = (await phone.read(ledgerProvider.notifier).record(draft))
      .valueOrNull!;
  await phone.read(captureServiceProvider).confirmed(capture, entry);
}

void main() {
  late FakeExchange server;
  late _Spy spy;

  setUp(() {
    server = FakeExchange();
    spy = _Spy();
  });

  test('RN-1107 · nenhuma resposta de pessoa vai como exemplo para a IA, '
      'nem as regras antigas com nome de gente', () async {
    final phone = _phone(server, spy, 'a');
    final memory = phone.read(answerMemoryProvider);
    await memory.remember(key: 'padaria boa vista', categoryId: 'bakery');
    await memory.remember(
      key: StatementLineResolver.personKey('João P Silva'),
      categoryId: 'home',
      aboutPerson: true,
    );
    final shelf = phone.read(captureShelfProvider);
    await shelf.learn(merchant: 'Maria Souza', categoryId: 'leisure');
    await shelf.learn(merchant: 'Posto Central', categoryId: 'transport');

    await _open(phone, 'c1', pixReceiptText);
    final request = spy.requests.single;

    expect(request.learnedRules, {
      'posto central': 'transport',
      'padaria boa vista': 'bakery',
    });
    expect(request.personalRules.keys, {
      'maria souza',
      StatementLineResolver.personKey('João P Silva'),
    });
  });

  test('RN-1116 · o que a captura aprende vira resposta lembrada e chega ao '
      'outro celular; a de pessoa vale lá e continua fora dos '
      'exemplos', () async {
    final a = _phone(server, _Spy(), 'a');
    final b = _phone(server, spy, 'b');
    await _confirm(a, await _open(a, 'c1', pixReceiptText), 'bakery');
    await _confirm(a, await _open(a, 'c2', _pixToPerson), 'home');
    await TwoPhones.sync(a);
    await TwoPhones.sync(b);

    final onB = await _open(b, 'c3', _pixToPerson);
    final request = spy.requests.single;

    expect(onB.proposal.category.value, 'home');
    expect(onB.proposal.category.source, FieldSource.learnedRule);
    expect(request.personalRules, {'joao p silva': 'home'});
    expect(request.learnedRules, {
      'lanchonete e restaurante sabor da praca': 'bakery',
    });
    final book = await b.read(ledgerProvider.future);
    expect(book.learnedAnswers.forKey('joao p silva')?.aboutPerson, isTrue);
  });
}
