import 'package:cajui/src/features/assistant/application/assistant_gateway.dart';
import 'package:cajui/src/features/assistant/application/speech_input.dart';
import 'package:cajui/src/features/assistant/infrastructure/http_assistant_gateway.dart';
import 'package:cajui/src/features/assistant/infrastructure/native_speech_input.dart';
import 'package:cajui/src/features/assistant/infrastructure/no_speech_input.dart';
import 'package:cajui/src/features/assistant/infrastructure/unpaired_assistant_gateway.dart';
import 'package:cajui/src/features/auth/application/device_directory.dart';
import 'package:cajui/src/features/auth/application/device_enrollment.dart';
import 'package:cajui/src/features/auth/application/device_key_store.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';
import 'package:cajui/src/features/auth/infrastructure/native_device_key_store.dart';
import 'package:cajui/src/features/auth/infrastructure/no_device_key_store.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:cajui/src/features/ledger/infrastructure/cajui_ledger_api.dart';
import 'package:cajui/src/features/ledger/infrastructure/event_store_ledger_journal.dart';
import 'package:cajui/src/features/ledger/infrastructure/ledger_event_codec.dart';
import 'package:cajui/src/features/ledger/infrastructure/no_ledger_uplink.dart';
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
    final api = _api(nativeCapture: nativeCapture);
    return [
      deviceKeyStoreProvider.overrideWithValue(api.keys),
      deviceEnrollmentProvider.overrideWithValue(api),
      deviceDirectoryProvider.overrideWithValue(api),
      ledgerJournalProvider.overrideWithValue(
        EventStoreLedgerJournal(
          store: store,
          codec: const LedgerEventCodec(categoryOf: _defaultCategory),
        ),
      ),
      captureShelfProvider.overrideWithValue(EventStoreCaptureShelf(store)),
      ..._server(api),
      ..._capture(inbox),
    ];
  }

  /// O que depende de haver identidade de aparelho: subir o livro e
  /// conversar com o assistente. Sem Keystore, nenhuma das duas existe.
  static List<Override> _server(CajuiApi api) => [
    ledgerUplinkProvider.overrideWithValue(
      api.keys.exists ? CajuiLedgerApi(api) : const NoLedgerUplink(),
    ),
    assistantGatewayProvider.overrideWithValue(
      api.keys.exists
          ? HttpAssistantGateway(api)
          : const UnpairedAssistantGateway(),
    ),
    speechInputProvider.overrideWithValue(
      api.keys.exists ? const NativeSpeechInput() : const NoSpeechInput(),
    ),
  ];

  static List<Override> _capture(NativeReceiptInbox? inbox) => [
    receiptInboxProvider.overrideWithValue(inbox ?? const NoReceiptInbox()),
    receiptReaderProvider.overrideWithValue(
      inbox == null
          ? const NoReceiptReader()
          : NativeReceiptReader(progress: inbox.progress),
    ),
  ];

  /// O caminho até o servidor. O aparelho só tem identidade onde há
  /// Keystore: sem ela não há sessão, e sem sessão o assistente diz a
  /// verdade em vez de fingir conversa.
  static CajuiApi _api({required bool nativeCapture}) => CajuiApi(
    baseUrl: CajuiApi.production,
    keys: nativeCapture
        ? const NativeDeviceKeyStore()
        : const NoDeviceKeyStore(),
  );

  static Category _defaultCategory(String id) =>
      DefaultCatalog.emptyBook.categoryOf(id);
}
