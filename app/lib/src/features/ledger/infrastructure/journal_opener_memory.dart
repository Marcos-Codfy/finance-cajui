import 'package:cajui/src/features/ledger/application/ledger_journal.dart';
import 'package:cajui/src/features/ledger/infrastructure/memory_ledger_journal.dart';

/// Na web, o livro vive só enquanto a aba está aberta (ADR-013).
Future<LedgerJournal> openLedgerJournal() async => MemoryLedgerJournal();
