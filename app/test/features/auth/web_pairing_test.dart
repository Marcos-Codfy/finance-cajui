import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/application/ledger_event.dart';
import 'package:cajui/src/features/ledger/application/ledger_journal.dart';
import 'package:cajui/src/features/ledger/infrastructure/no_ledger_uplink.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_enrollment.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/sample_plan.dart';
import '../../support/test_scope.dart';

/// O livro do servidor como a web o vê: vazio antes de entrar, e o mês
/// inteiro depois — é a sessão que decide o que a leitura devolve.
final class _ServerBook implements LedgerJournal {
  new(this._enrollment);

  final FakeEnrollment _enrollment;
  int reads = 0;

  /// O servidor com sessão aberta e nada do mês: o celular ainda não enviou.
  bool alwaysEmpty = false;

  @override
  Future<List<LedgerEvent>> readAll() async {
    reads++;
    if (alwaysEmpty || _enrollment.codes.isEmpty) return const [];
    return samplePlanEvents;
  }

  @override
  Future<void> append(LedgerEvent event) =>
      throw StateError('a consulta não grava');
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

Future<(_ServerBook, FakeEnrollment)> _openWeb(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final enrollment = FakeEnrollment();
  final book = _ServerBook(enrollment);
  await tester.pumpWidget(
    ProviderScope(
      overrides: testOverrides(
        journal: book,
        uplink: const NoLedgerUplink(),
        enrollment: enrollment,
      ),
      child: const CajuiApp(),
    ),
  );
  await _settle(tester);
  return (book, enrollment);
}

void main() {
  group('ADR-013 · a consulta pela web entra com o código do celular', () {
    testWidgets('o painel vazio leva à entrada, e a entrada relê o livro', (
      tester,
    ) async {
      final (book, enrollment) = await _openWeb(tester);
      expect(find.text('Nada deste mês por aqui ainda'), findsOneWidget);
      expect(find.textContaining('recarregue'), findsNothing);

      await tester.tap(find.text('Entrar com o código'));
      await _settle(tester);

      expect(find.text('Entrar com o código do celular'), findsOneWidget);
      expect(find.textContaining('Abrir no computador'), findsOneWidget);
      expect(find.text('Nome deste aparelho'), findsNothing);
      expect(find.text('Cadastrar'), findsNothing);

      final readsBefore = book.reads;
      await tester.enterText(find.byType(EditableText).first, '5BHMRM6J');
      await tester.pump();
      await tester.tap(find.text('Entrar'));
      await _settle(tester);

      expect(enrollment.codes, ['5BHMRM6J']);
      expect(book.reads, greaterThan(readsBefore), reason: 'releu o livro');
      expect(find.text('Nada deste mês por aqui ainda'), findsNothing);
      // T-12: com o mês na tela, a consulta continua sem porta para gravar.
      expect(find.text('Novo lançamento'), findsNothing);
      expect(find.bySemanticsLabel('Plano do mês'), findsNothing);
      expect(find.text('Cadastrar a renda'), findsNothing);
    });

    testWidgets('entrou, mas o servidor não tem o mês: a página diz isso e '
        '"Atualizar" relê sem perder a sessão', (tester) async {
      final enrollment = FakeEnrollment();
      final book = _ServerBook(enrollment)..alwaysEmpty = true;
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides(
            journal: book,
            uplink: const NoLedgerUplink(),
            enrollment: enrollment,
          ),
          child: const CajuiApp(),
        ),
      );
      await _settle(tester);
      await tester.tap(find.text('Entrar com o código'));
      await _settle(tester);
      await tester.enterText(find.byType(EditableText).first, '5BHMRM6J');
      await tester.pump();
      await tester.tap(find.text('Entrar'));
      await _settle(tester);

      expect(
        find.text('O servidor ainda não tem nada deste mês'),
        findsOneWidget,
      );
      expect(find.text('Entrar com o código'), findsNothing);
      final readsBefore = book.reads;
      book.alwaysEmpty = false;
      await tester.tap(find.text('Atualizar'));
      await _settle(tester);

      expect(book.reads, greaterThan(readsBefore));
      expect(
        enrollment.codes,
        hasLength(1),
        reason: 'não pediu código de novo',
      );
      expect(
        find.text('O servidor ainda não tem nada deste mês'),
        findsNothing,
      );
    });

    testWidgets('no celular, a tela continua sendo o cadastro', (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides(enrollment: FakeEnrollment(refused: true)),
          child: const CajuiApp(),
        ),
      );
      await _settle(tester);

      expect(find.text('Seu mês começa aqui'), findsOneWidget);
      expect(find.text('Começar'), findsOneWidget);
      expect(find.text('Entrar com o código'), findsNothing);
    });
  });

  group('ADR-013 · o convite para o computador diz para onde ir', () {
    Future<void> openDevices(WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: testOverrides(journal: MemoryLedgerJournal()),
          child: const CajuiApp(),
        ),
      );
      await _settle(tester);
      await tester.tap(find.bySemanticsLabel('Ajustes'));
      await _settle(tester);
      await tester.tap(find.text('Aparelhos com acesso'));
      await _settle(tester);
    }

    testWidgets('para o navegador: endereço, e a aba que é a sessão', (
      tester,
    ) async {
      await openDevices(tester);
      expect(find.text('S22'), findsOneWidget);

      await tester.tap(find.text('Abrir no computador'));
      await _settle(tester);

      expect(find.text('WXYZ5678'), findsOneWidget);
      expect(find.textContaining('cajui-teal.vercel.app'), findsOneWidget);
      expect(find.textContaining('2 minutos'), findsOneWidget);
      expect(find.textContaining('abra o Cajui'), findsNothing);
      expect(find.text('Cadastrar outro aparelho'), findsNothing);
    });

    testWidgets('para outro celular: o cadastro', (tester) async {
      await openDevices(tester);

      await tester.tap(find.text('Cadastrar outro aparelho'));
      await _settle(tester);

      expect(find.text('ABCD1234EF'), findsOneWidget);
      expect(find.textContaining('abra o Cajui'), findsOneWidget);
      expect(find.textContaining('10 minutos'), findsOneWidget);
      expect(find.textContaining('vercel'), findsNothing);
    });
  });
}
