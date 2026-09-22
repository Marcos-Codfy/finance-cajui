import 'package:api_contract/api_contract.dart';
import 'package:cajui/src/features/receipts/application/receipt_inbox.dart';
import 'package:cajui/src/features/receipts/application/shared_item.dart';
import 'package:flutter/services.dart';

/// A caixa de entrada ligada ao módulo nativo de captura do Android
/// (ADR-006), pelo canal `app.cajui/capture`.
final class NativeReceiptInbox implements ReceiptInbox {
  /// Cria a caixa. Os canais entram por parâmetro para o teste simular o
  /// lado nativo.
  new({
    this._methods = const MethodChannel('app.cajui/capture'),
    EventChannel events = const EventChannel('app.cajui/capture/events'),
  }) : _events = events.receiveBroadcastStream().map(_asMap);

  final MethodChannel _methods;
  final Stream<Map<Object?, Object?>> _events;

  static Map<Object?, Object?> _asMap(Object? event) =>
      event is Map ? event : const {};

  /// O progresso da leitura em curso: página e total, vindos do trabalho
  /// feito, e não de animação (RNF-PERF-06).
  Stream<(int page, int of)> get progress => _events
      .where((event) => event['type'] == 'progress')
      .map((event) => (event['page']! as int, event['of']! as int));

  @override
  Stream<void> get arrivals =>
      _events.where((event) => event['type'] == 'arrived');

  @override
  Future<List<SharedItem>> takePending() async {
    final raw = await _methods.invokeListMethod<Map<Object?, Object?>>(
      'takePending',
    );
    return [...?raw?.map(_item)];
  }

  /// O que vem do outro lado do canal também é entrada: campo que falta ou
  /// código desconhecido vira recusa, não exceção.
  SharedItem _item(Map<Object?, Object?> raw) {
    final id = raw['id'] as String? ?? '';
    final error = raw['error'] as String?;
    if (error != null) {
      return RejectedShare(
        id: id,
        code: ErrorCode.tryParse(error) ?? ErrorCode.capt02,
        detail: (raw['detail'] as Map?)?.cast<String, Object?>() ?? const {},
      );
    }
    final path = raw['path'] as String?;
    final text = raw['text'] as String?;
    if (path != null) {
      return SharedFile(id: id, path: path, isPdf: raw['kind'] == 'pdf');
    }
    if (text != null) return SharedText(id: id, text: text);
    return RejectedShare(id: id, code: ErrorCode.capt02);
  }

  @override
  bool get canPhotograph => true;

  @override
  Future<bool> takePhoto() async =>
      await _methods.invokeMethod<bool>('takePhoto') ?? false;

  @override
  Future<void> discard(SharedFile file) =>
      _methods.invokeMethod<bool>('discard', {'path': file.path});
}
