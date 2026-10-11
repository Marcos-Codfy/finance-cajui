/// As telas que uma notificação do Cajui pede para abrir (RN-849): tocar no
/// aviso de domingo abre a revisão da semana, e não o painel; tocar num
/// lembrete de vencimento abre a tela do assunto (RN-1087).
abstract interface class LaunchRequests {
  /// O pedido que abriu o app, se houve; quem lê o consome.
  Future<String?> takePending();

  /// Os pedidos que chegam com o app já aberto.
  Stream<String> get requests;
}
