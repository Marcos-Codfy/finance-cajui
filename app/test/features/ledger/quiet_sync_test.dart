import 'dart:async';

import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:cajui/src/features/ledger/application/quiet_sync.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

final _today = LocalDate(2026, 9, 22);

/// Um servidor de mentira que conta quantas subidas começaram e segura a
/// primeira, para o teste poder pedir outra enquanto ela está no ar.
final class _FakeUplink implements LedgerUplink {
  new({this.session = true});

  final bool session;
  int runs = 0;
  final List<String> sent = [];
  Completer<void>? hold;
  ErrorCode? refuse;

  @override
  bool get isPaired => true;

  @override
  bool get hasOpenSession => session;

  @override
  Future<(Set<String>, ErrorCode?)> remoteCategories() async {
    runs++;
    if (hold case final espera?) await espera.future;
    final erro = refuse;
    if (erro != null) throw StateError('sem rede');
    return (const <String>{'groceries'}, null);
  }

  @override
  Future<(Set<String>, ErrorCode?)> remoteCards() async =>
      (const <String>{}, null);

  @override
  Future<ErrorCode?> sendCard(Map<String, Object?> card) async => null;

  @override
  Future<ErrorCode?> sendPlan(Map<String, Object?> plan) async => null;

  @override
  Future<(Map<String, String>, ErrorCode?)> remoteEntries() async =>
      (const <String, String>{}, null);

  @override
  Future<ErrorCode?> sendCategory(Map<String, Object?> category) async => null;

  @override
  Future<ErrorCode?> sendEntry(CreateEntryRequest entry) async {
    sent.add(entry.id);
    return null;
  }

  @override
  Future<ErrorCode?> reviseEntry(CreateEntryRequest entry) async => null;

  @override
  Future<ErrorCode?> cancelEntry(String id) async => null;
}

Entry _entry(String id) => Entry.create(
  id: id,
  description: 'Padaria',
  amount: const Money.fromCents(850),
  occurredOn: _today,
  category: DefaultCatalog.emptyBook.categoryOf('groceries'),
  paymentLines: [
    DefaultCatalog.emptyBook.methodOf('pix').line(const Money.fromCents(850)),
  ],
  today: _today,
).valueOrNull!;

LedgerBook _book(List<String> ids) {
  final base = DefaultCatalog.emptyBook;
  return LedgerBook(
    categories: base.categories,
    paymentMethods: base.paymentMethods,
    entries: [for (final id in ids) _entry(id)],
  );
}

void main() {
  group('RN-781 · o livro sobe sozinho depois de lançar', () {
    test('com sessão aberta, sobe sem ninguém pedir', () async {
      final uplink = _FakeUplink();
      final quiet = QuietSync(uplink)..schedule(_book(['e1']));

      await quiet.settled;

      expect(uplink.sent, ['e1']);
    });

    test('sem sessão aberta não sobe nada: abrir sessão pediria a digital '
        'no meio do lançamento', () async {
      final uplink = _FakeUplink(session: false);

      QuietSync(uplink).schedule(_book(['e1']));
      await Future<void>.delayed(Duration.zero);

      expect(uplink.runs, 0);
      expect(uplink.sent, isEmpty);
    });

    test('lançar três coisas seguidas não abre três subidas, e a última '
        'sobe com o livro mais recente', () async {
      final uplink = _FakeUplink()..hold = Completer<void>();
      final quiet = QuietSync(uplink)..schedule(_book(['e1']));
      await Future<void>.delayed(Duration.zero);

      quiet
        ..schedule(_book(['e1', 'e2']))
        ..schedule(_book(['e1', 'e2', 'e3']));
      uplink
        ..hold!.complete()
        ..hold = null;
      await quiet.settled;

      expect(uplink.runs, 2, reason: 'uma no ar, e uma só para a fila');
      expect(uplink.sent, ['e1', 'e1', 'e2', 'e3']);
    });

    test('falhar não chega à tela: o livro daqui já está gravado', () async {
      final uplink = _FakeUplink()..refuse = ErrorCode.srv01;
      final quiet = QuietSync(uplink)..schedule(_book(['e1']));

      await expectLater(quiet.settled, completes);
      expect(uplink.sent, isEmpty);
    });
  });
}
