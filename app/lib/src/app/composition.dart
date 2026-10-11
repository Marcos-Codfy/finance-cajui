import 'package:cajui/src/core/settings/event_store_preferences.dart';
import 'package:cajui/src/core/settings/no_preferences_store.dart';
import 'package:cajui/src/core/settings/preferences_store.dart';
import 'package:cajui/src/features/assistant/application/assistant_gateway.dart';
import 'package:cajui/src/features/assistant/application/speech_input.dart';
import 'package:cajui/src/features/assistant/infrastructure/http_assistant_gateway.dart';
import 'package:cajui/src/features/assistant/infrastructure/native_speech_input.dart';
import 'package:cajui/src/features/assistant/infrastructure/no_speech_input.dart';
import 'package:cajui/src/features/auth/application/household_key_store.dart';
import 'package:cajui/src/features/auth/infrastructure/browser_household_key.dart';
import 'package:cajui/src/features/auth/infrastructure/built_in_household_key.dart';
import 'package:cajui/src/features/auth/infrastructure/cajui_api.dart';
import 'package:cajui/src/features/auth/infrastructure/native_device_key_store.dart';
import 'package:cajui/src/features/auth/infrastructure/no_device_key_store.dart';
import 'package:cajui/src/features/home_widget/application/home_widget_providers.dart';
import 'package:cajui/src/features/home_widget/infrastructure/native_home_screen.dart';
import 'package:cajui/src/features/ledger/application/default_catalog.dart';
import 'package:cajui/src/features/ledger/application/ledger_downlink.dart';
import 'package:cajui/src/features/ledger/application/ledger_providers.dart';
import 'package:cajui/src/features/ledger/application/ledger_uplink.dart';
import 'package:cajui/src/features/ledger/infrastructure/cajui_ledger_api.dart';
import 'package:cajui/src/features/ledger/infrastructure/event_store_ledger_journal.dart';
import 'package:cajui/src/features/ledger/infrastructure/ledger_event_codec.dart';
import 'package:cajui/src/features/ledger/infrastructure/no_ledger_uplink.dart';
import 'package:cajui/src/features/ledger/infrastructure/remote_ledger_journal.dart';
import 'package:cajui/src/features/notifications/application/notification_providers.dart';
import 'package:cajui/src/features/notifications/infrastructure/native_notifications_channel.dart';
import 'package:cajui/src/features/receipts/application/receipt_providers.dart';
import 'package:cajui/src/features/receipts/infrastructure/event_store_capture_shelf.dart';
import 'package:cajui/src/features/receipts/infrastructure/http_receipt_classifier.dart';
import 'package:cajui/src/features/receipts/infrastructure/native_receipt_inbox.dart';
import 'package:cajui/src/features/receipts/infrastructure/native_receipt_reader.dart';
import 'package:cajui/src/features/receipts/infrastructure/no_receipt_inbox.dart';
import 'package:cajui/src/features/receipts/infrastructure/no_receipt_reader.dart';
import 'package:cajui/src/features/review/application/review_providers.dart';
import 'package:cajui/src/features/review/infrastructure/event_store_review_log.dart';
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
  /// As ligações para o registro [store]. Com [nativeCapture], o app é o do
  /// Android: captura pelo módulo nativo, livro no registro cifrado, chave
  /// da casa compilada. Sem, é a consulta na web: livro do servidor, chave
  /// digitada uma vez.
  static List<Override> overrides({
    required EventStore store,
    required bool nativeCapture,
  }) {
    final inbox = nativeCapture ? NativeReceiptInbox() : null;
    final keys = nativeCapture
        ? const BuiltInHouseholdKey()
        : const BrowserHouseholdKey();
    final api = _api(keys, nativeCapture: nativeCapture);
    return [
      householdKeyProvider.overrideWithValue(keys),
      _journal(store, api, local: nativeCapture),
      // A descida do livro (BL-062): o que outro aparelho fez chegando aqui.
      // É o mesmo leitor que a web usa como livro inteiro.
      ledgerDownlinkProvider.overrideWithValue(
        RemoteLedgerJournal(api, categoryOf: _defaultCategory),
      ),
      captureShelfProvider.overrideWithValue(EventStoreCaptureShelf(store)),
      _preferences(store, local: nativeCapture),
      ..._server(api, local: nativeCapture),
      ..._capture(inbox, api),
      ..._device(store, native: nativeCapture),
    ];
  }

  /// As notificações do banco, o widget da tela inicial e a revisão da
  /// semana (ADR-025). Um canal só atende as três portas das notificações:
  /// o lado nativo fala com um tratador por canal. Na web, só o registro do
  /// que foi revisto — inerte lá, onde nada chega para revisar.
  static List<Override> _device(EventStore store, {required bool native}) {
    final review = reviewLogProvider.overrideWithValue(
      EventStoreReviewLog(store),
    );
    if (!native) return [review];
    final channel = NativeNotificationsChannel();
    return [
      review,
      bankNoticeDeviceProvider.overrideWithValue(channel),
      notificationAccessProvider.overrideWithValue(channel),
      launchRequestsProvider.overrideWithValue(channel),
      homeScreenProvider.overrideWithValue(const NativeHomeScreen()),
    ];
  }

  /// No aparelho, o livro é o registro cifrado. Na web, é o que o servidor
  /// tem: ela não tem registro próprio (ADR-013).
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
  /// (BL-030). Na web, em lugar nenhum: a chave da casa é o único rastro
  /// que a consulta deixa no navegador, e por escolha de quem entrou.
  static Override _preferences(EventStore store, {required bool local}) =>
      preferencesStoreProvider.overrideWithValue(
        local ? EventStorePreferences(store) : const NoPreferencesStore(),
      );

  /// O que fala com o servidor: subir o livro, conversar com o assistente,
  /// ditar. A web só lê e conversa — o livro dela desce, não sobe.
  static List<Override> _server(CajuiApi api, {required bool local}) => [
    ledgerUplinkProvider.overrideWithValue(
      local ? CajuiLedgerApi(api) : const NoLedgerUplink(),
    ),
    assistantGatewayProvider.overrideWithValue(HttpAssistantGateway(api)),
    speechInputProvider.overrideWithValue(
      local ? const NativeSpeechInput() : const NoSpeechInput(),
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
    // como rede embaixo: sem chave, sem rede ou sem crédito, vale a
    // proposta local (RN-752).
    if (inbox != null)
      receiptClassifierProvider.overrideWithValue(
        HttpReceiptClassifier(api, const RuleBasedClassifier()),
      ),
  ];

  /// O caminho até o servidor, com a chave da casa e o nome do aparelho —
  /// que no Android sai do Keystore, e na web é "web".
  static CajuiApi _api(HouseholdKeyStore keys, {required bool nativeCapture}) =>
      CajuiApi(
        baseUrl: CajuiApi.production,
        keys: keys,
        identity: nativeCapture
            ? const NativeDeviceKeyStore()
            : const NoDeviceKeyStore(),
      );

  static Category _defaultCategory(String id) =>
      DefaultCatalog.emptyBook.categoryOf(id);
}
