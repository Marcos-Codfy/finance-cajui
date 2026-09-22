import 'dart:async';

import 'package:cajui/src/features/receipts/application/receipt_inbox.dart';
import 'package:cajui/src/features/receipts/application/shared_item.dart';

/// Uma caixa de entrada que o teste enche à mão, como se outro app tivesse
/// compartilhado.
class FakeInbox implements ReceiptInbox {
  final _arrivals = StreamController<void>.broadcast();
  final List<SharedItem> _pending = [];

  /// Os arquivos que o app mandou apagar.
  final List<String> discarded = [];

  /// Quantas vezes o app pediu a câmera.
  int photoRequests = 0;

  /// Se o aparelho simulado tem câmera.
  bool hasCamera = true;

  /// O que a câmera devolve quando é chamada: o que chegaria pela fila.
  List<SharedItem> photo = const [];

  /// Faz [items] chegarem, na ordem dada.
  void share(List<SharedItem> items) {
    _pending.addAll(items);
    _arrivals.add(null);
  }

  @override
  Stream<void> get arrivals => _arrivals.stream;

  @override
  Future<List<SharedItem>> takePending() async {
    final taken = [..._pending];
    _pending.clear();
    return taken;
  }

  @override
  bool get canPhotograph => hasCamera;

  @override
  Future<bool> takePhoto() async {
    photoRequests++;
    if (!hasCamera) return false;
    if (photo.isNotEmpty) share(photo);
    return true;
  }

  @override
  Future<void> discard(SharedFile file) async => discarded.add(file.path);
}
