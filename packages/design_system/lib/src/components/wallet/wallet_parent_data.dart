import 'package:flutter/rendering.dart';

/// O que a pilha de carteira guarda de cada cartão: o lugar na coluna (o
/// `offset`) e a matriz com que ele foi pintado por último — para o toque e
/// o leitor de tela acharem o cartão onde ele aparece, e não onde o layout o
/// pôs.
class WalletParentData extends ContainerBoxParentData<RenderBox> {
  /// A matriz do último quadro, já com o lugar na coluna. `null` antes do
  /// primeiro quadro: vale só o `offset`.
  Matrix4? transform;

  /// A camada da matriz, reaproveitada de um quadro para o outro.
  final LayerHandle<TransformLayer> moved = LayerHandle();

  /// A camada do esmaecer, reaproveitada de um quadro para o outro.
  final LayerHandle<OpacityLayer> faded = LayerHandle();

  /// A matriz em vigor: a do último quadro, ou só o lugar na coluna.
  Matrix4 get effective =>
      transform ?? Matrix4.translationValues(offset.dx, offset.dy, 0);

  @override
  void detach() {
    moved.layer = null;
    faded.layer = null;
    super.detach();
  }
}
