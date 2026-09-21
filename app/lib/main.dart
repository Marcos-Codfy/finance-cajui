import 'package:cajui/src/app/cajui_app.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/ledger/infrastructure/journal_opener.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A raiz de composição: o único lugar que conhece a plataforma e liga cada
/// porta da aplicação ao adaptador que vale nela.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Na web o Flutter só monta a árvore de acessibilidade quando alguém pede,
  // e leitor de tela não sabe pedir. Ligada desde o início, a página nasce
  // legível para ele (ADR-013).
  if (kIsWeb) SemanticsBinding.instance.ensureSemantics();
  final journal = await openLedgerJournal();
  runApp(
    ProviderScope(
      overrides: [ledgerJournalProvider.overrideWithValue(journal)],
      child: const CajuiApp(),
    ),
  );
}
