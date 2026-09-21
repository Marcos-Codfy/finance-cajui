/// Abre o registro de eventos do jeito certo para a plataforma: arquivo
/// cifrado onde há disco (Android), memória onde não deve haver (web).
///
/// A escolha é feita na compilação. O código que abre arquivo nem chega a
/// entrar no pacote da web.
library;

export 'event_store_opener_memory.dart'
    if (dart.library.io) 'event_store_opener_file.dart';
