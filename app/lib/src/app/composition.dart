import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/ledger/infrastructure/event_store_ledger_journal.dart';
import 'package:cajui/src/features/ledger/infrastructure/ledger_event_codec.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:cajui/src/features/receipts/infrastructure/event_store_capture_shelf.dart';
import 'package:cajui/src/features/receipts/infrastructure/native_receipt_inbox.dart';
import 'package:cajui/src/features/receipts/infrastructure/native_receipt_reader.dart';
import 'package:cajui/src/features/receipts/infrastructure/no_receipt_inbox.dart';
import 'package:cajui/src/features/receipts/infrastructure/no_receipt_reader.dart';
import 'package:domain/domain.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:persistence/event_store.dart';

/// A raiz de composição: o **único** lugar do app que conhece os adaptadores
/// e os liga às portas da aplicação (ADR-001).
///
/// As camadas de dentro não se enxergam de lado — o verificador reprova —, e
/// é aqui que as pontas se encontram. Trocar arquivo cifrado por outro
/// armazenamento, ou o módulo nativo por outro leitor, muda este arquivo e
/// mais nenhum.
abstract final class Composition {
  /// As ligações para o registro [store]. Com [nativeCapture], a captura usa
  /// o módulo nativo do Android; sem, nunca chega comprovante nenhum.
  static List<Override> overrides({
    required EventStore store,
    required bool nativeCapture,
  }) {
    final inbox = nativeCapture ? NativeReceiptInbox() : null;
    return [
      ledgerJournalProvider.overrideWithValue(
        EventStoreLedgerJournal(
          store: store,
          codec: const LedgerEventCodec(categoryOf: _defaultCategory),
        ),
      ),
      captureShelfProvider.overrideWithValue(EventStoreCaptureShelf(store)),
      receiptInboxProvider.overrideWithValue(inbox ?? const NoReceiptInbox()),
      receiptReaderProvider.overrideWithValue(
        inbox == null
            ? const NoReceiptReader()
            : NativeReceiptReader(progress: inbox.progress),
      ),
    ];
  }

  static Category _defaultCategory(String id) =>
      DefaultCatalog.emptyBook.categoryOf(id);
}
