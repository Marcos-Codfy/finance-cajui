import 'package:domain/domain.dart';
import 'package:meta/meta.dart';

/// O que o lado nativo deixou na fila para o Dart tratar (ADR-025).
///
/// A fila é uma só para os dois pedidos — a notificação que chegou do banco
/// e o "Desfazer" tocado na notificação do Cajui —, e por isso eles são
/// tratados na ordem em que aconteceram: desfazer nunca passa na frente do
/// lançamento que ele desfaz.
@immutable
sealed class QueuedNotice {
  const new({required this.id});

  /// A chave do item na fila. Para a notificação do banco, é derivada dela
  /// mesma: a mesma notificação repetida tem a mesma chave.
  final String id;
}

/// Uma notificação de um app de banco da lista.
final class BankNotice extends QueuedNotice {
  /// Cria o item.
  const new({required super.id, required this.notification});

  /// A notificação, como chegou.
  final BankNotification notification;
}

/// O "Desfazer" tocado na notificação de um lançamento automático.
final class UndoNotice extends QueuedNotice {
  /// Cria o pedido de desfazer [entryId].
  const new({required super.id, required this.entryId});

  /// O lançamento a cancelar.
  final String entryId;
}
