import 'package:cajui/src/core/settings/event_store_preferences.dart';
import 'package:cajui/src/core/settings/no_preferences_store.dart';
import 'package:cajui/src/core/settings/preferences_store.dart';
import 'package:cajui/src/features/assistant/application/assistant_gateway.dart';
import 'package:cajui/src/features/assistant/application/speech_input.dart';
import 'package:cajui/src/features/assistant/infrastructure/http_assistant_gateway.dart';
import 'package:cajui/src/features/assistant/infrastructure/native_speech_input.dart';
import 'package:cajui/src/features/assistant/infrastructure/no_speech_input.dart';
import 'package:cajui/src/features/auth/application/device_directory.dart';
import 'package:cajui/src/features/auth/application/device_enrollment.dart';
import 'package:cajui/src/features/auth/application/device_key_store.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';
import 'package:cajui/src/features/auth/infrastructure/native_device_key_store.dart';
import 'package:cajui/src/features/auth/infrastructure/no_device_key_store.dart';
import 'package:cajui/src/features/auth/infrastructure/web_session_enrollment.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:cajui/src/features/ledger/infrastructure/cajui_ledger_api.dart';
import 'package:cajui/src/features/ledger/infrastructure/event_store_ledger_journal.dart';
import 'package:cajui/src/features/ledger/infrastructure/ledger_event_codec.dart';
import 'package:cajui/src/features/ledger/infrastructure/no_ledger_uplink.dart';
import 'package:cajui/src/features/ledger/infrastructure/remote_ledger_journal.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:cajui/src/features/receipts/infrastructure/event_store_capture_shelf.dart';
import 'package:cajui/src/features/receipts/infrastructure/http_receipt_classifier.dart';
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
      // Sem Keystore — a web —, a mesma tela de código abre uma sessão de
      // consulta em vez de cadastrar um aparelho (ADR-013).
      deviceEnrollmentProvider.overrideWithValue(
        api.keys.exists ? api : WebSessionEnrollment(api),
      ),
      deviceDirectoryProvider.overrideWithValue(api),
      _journal(store, api, local: nativeCapture),
      captureShelfProvider.overrideWithValue(EventStoreCaptureShelf(store)),
      _preferences(store, local: nativeCapture),
      ..._server(api),
      ..._capture(inbox, api),
    ];
  }

  /// No aparelho, o livro é o registro cifrado. Na web, é o que o servidor
  /// tem: ela não tem registro próprio, e o livro vazio que usava antes
  /// mostrava "R$ 0,00" com cara de verdade (ADR-013).
  static Override _journal(
    EventStore store,
    CajuiApi api, {
    required bool local,
  }) => ledgerJournalProvider.overrideWithValue(
    local
        ? EventStoreLedgerJournal(
            store: store,
            codec: const LedgerEventCodec(categoryOf: _defaultCategory),
          )
        : RemoteLedgerJournal(api, categoryOf: _defaultCategory),
  );

  /// As escolhas de som, vibração e tema vivem no mesmo registro cifrado
  /// (BL-030). Na web, em lugar nenhum: lá a aba é a sessão, e guardar
  /// escolha seria deixar rastro de quem só veio olhar.
  static Override _preferences(EventStore store, {required bool local}) =>
      preferencesStoreProvider.overrideWithValue(
        local ? EventStorePreferences(store) : const NoPreferencesStore(),
      );

  /// O que depende de haver identidade de aparelho: subir o livro e
  /// conversar com o assistente. Sem Keystore, nenhuma das duas existe.
  static List<Override> _server(CajuiApi api) => [
    ledgerUplinkProvider.overrideWithValue(
      api.keys.exists ? CajuiLedgerApi(api) : const NoLedgerUplink(),
    ),
    // A conversa com o Buriti é a única coisa que a web faz de verdade: ela
    // não tem o livro local, e o contexto é montado no servidor de qualquer
    // jeito (RN-915). Na web o gateway é o mesmo; o que muda é como a
    // sessão nasce.
    assistantGatewayProvider.overrideWithValue(HttpAssistantGateway(api)),
    speechInputProvider.overrideWithValue(
      api.keys.exists ? const NativeSpeechInput() : const NoSpeechInput(),
    ),
  ];

  static List<Override> _capture(NativeReceiptInbox? inbox, CajuiApi api) => [
    receiptInboxProvider.overrideWithValue(inbox ?? const NoReceiptInbox()),
    receiptReaderProvider.overrideWithValue(
      inbox == null
          ? const NoReceiptReader()
          : NativeReceiptReader(progress: inbox.progress),
    ),
    // A IA do servidor por cima das regras locais (ADR-010), e as regras
    // como rede embaixo: sem sessão, sem rede ou sem crédito, vale a
    // proposta local (RN-752). Onde não há captura também não há o que
    // classificar, e o classificador de regras basta.
    if (inbox != null)
      receiptClassifierProvider.overrideWithValue(
        HttpReceiptClassifier(api, const RuleBasedClassifier()),
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
