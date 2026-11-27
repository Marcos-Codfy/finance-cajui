import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A tela de armazenamento do aparelho: a saída do `E-STORAGE-01`, para a
/// pessoa liberar espaço sem ter de procurar onde fica.
abstract interface class StorageSettings {
  /// Abre a tela; onde não há tela para abrir, não faz nada.
  Future<void> open();
}

/// A porta do armazenamento. A raiz do app liga ao canal nativo no
/// Android; sem ligação, o botão não leva a lugar nenhum — e a tela mostra
/// também o "Tentar de novo", que funciona em qualquer lugar.
final storageSettingsProvider = Provider<StorageSettings>(
  (ref) => const _Nowhere(),
);

final class _Nowhere implements StorageSettings {
  const new();

  @override
  Future<void> open() async {}
}
