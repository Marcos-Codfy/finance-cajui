/// Só a porta do registro de eventos e o evento gravado — sem `dart:io`.
///
/// Quem compila também para a web (o app) importa esta biblioteca para
/// escrever contra a porta, e deixa a biblioteca completa, que abre arquivo,
/// para o código que só roda onde há disco.
library;

export 'src/event_store.dart';
export 'src/stored_event.dart';
