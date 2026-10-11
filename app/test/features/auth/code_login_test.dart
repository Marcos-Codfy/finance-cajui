import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/auth/application/code_exchange.dart';
import 'package:cajui/src/features/ledger/infrastructure/no_ledger_uplink.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_household_key.dart';
import '../../support/memory_ledger_journal.dart';
import '../../support/test_scope.dart';

/// O servidor de mentira: só o código [valid] abre sessão; com [down], ele
/// responde esse erro a tudo.
final class _Exchange implements CodeExchange {
  new(this.valid, {this.down});

  final String valid;
  final ErrorCode? down;
  final List<String> tried = [];

  @override
  Future<CodeOutcome> tokenFor(String code) async {
    tried.add(code);
    if (down != null) return (token: null, error: down, retryAfterSeconds: 30);
    return code == valid
        ? (
            token: 'token-da-sessao-de-consulta', // scan-secrets: exemplo
            error: null,
            retryAfterSeconds: null,
          )
        : (token: null, error: ErrorCode.auth04, retryAfterSeconds: null);
  }
}

Finder get _field => find.descendant(
  of: find.byType(CajuiFieldFrame),
  matching: find.byType(EditableText),
);

Future<FakeHouseholdKey> _openWeb(WidgetTester tester, CodeExchange e) async {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final keys = FakeHouseholdKey(null);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        ...testOverrides(
          journal: MemoryLedgerJournal(),
          uplink: const NoLedgerUplink(),
          householdKey: keys,
        ),
        codeExchangeProvider.overrideWithValue(e),
      ],
      child: const CajuiApp(),
    ),
  );
  await tester.pump();
  return keys;
}

void main() {
  testWidgets('ADR-027 · na web, o código de seis dígitos do autenticador '
      'entra, e o que fica guardado é a sessão, não o código', (tester) async {
    final exchange = _Exchange('482913');
    final keys = await _openWeb(tester, exchange);

    await tester.enterText(_field, '482913');
    await tester.pump();
    await tester.tap(find.text('Entrar').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(exchange.tried, ['482913']);
    expect(keys.key, 'token-da-sessao-de-consulta');
  });

  testWidgets('E-AUTH-04 · código que não serviu diz o que fazer, e nada '
      'fica guardado', (tester) async {
    final keys = await _openWeb(tester, _Exchange('482913'));

    await tester.enterText(_field, '000000');
    await tester.pump();
    await tester.tap(find.text('Entrar').last);
    await tester.pump();

    expect(find.textContaining('Esse código não serviu'), findsOneWidget);
    expect(keys.key, isNull);
  });

  testWidgets('a chave da casa continua entrando, sem passar pelo código', (
    tester,
  ) async {
    final exchange = _Exchange('482913');
    final keys = await _openWeb(tester, exchange);

    await tester.enterText(_field, 'chave-da-casa-de-teste-com-tamanho-bom');
    await tester.pump();
    await tester.tap(find.text('Entrar').last);
    await tester.pump();

    expect(exchange.tried, isEmpty);
    expect(keys.key, 'chave-da-casa-de-teste-com-tamanho-bom');
  });

  testWidgets('o código digitado como o autenticador mostra, "482 913", '
      'também entra', (tester) async {
    final exchange = _Exchange('482913');
    final keys = await _openWeb(tester, exchange);

    await tester.enterText(_field, '482 913');
    await tester.pump();
    await tester.tap(find.text('Entrar').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(exchange.tried, ['482913']);
    expect(keys.key, 'token-da-sessao-de-consulta');
  });

  testWidgets('E-NET-01 · sem rede, a frase é a da rede, e não "esse código '
      'não serviu"', (tester) async {
    final keys = await _openWeb(
      tester,
      _Exchange('482913', down: ErrorCode.net01),
    );

    await tester.enterText(_field, '482913');
    await tester.pump();
    await tester.tap(find.text('Entrar').last);
    await tester.pump();

    expect(find.textContaining('Sem conexão agora'), findsOneWidget);
    expect(find.textContaining('Esse código não serviu'), findsNothing);
    expect(keys.key, isNull);
  });

  testWidgets('E-RATE-01 · o limite de taxa diz quanto esperar', (
    tester,
  ) async {
    await _openWeb(tester, _Exchange('482913', down: ErrorCode.rate01));

    await tester.enterText(_field, '482913');
    await tester.pump();
    await tester.tap(find.text('Entrar').last);
    await tester.pump();

    expect(find.textContaining('em 30 segundos'), findsOneWidget);
  });
}
