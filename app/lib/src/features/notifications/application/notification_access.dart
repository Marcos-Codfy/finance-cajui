/// A permissão de ler as notificações dos bancos, que só a pessoa dá, na
/// tela do sistema (ADR-025).
///
/// O Cajui não tem chave própria para isto: ligado é o Android ter dado o
/// acesso; desligado, não. Assim a escolha mora num lugar só, e o que a
/// tela de Ajustes mostra é sempre a verdade.
abstract interface class NotificationAccess {
  /// Se o aparelho tem leitor de notificações — só o Android.
  bool get isSupported;

  /// Se a pessoa liberou o acesso às notificações.
  Future<bool> isGranted();

  /// Pede a permissão de postar notificações (Android 13 em diante) e abre
  /// a tela do sistema onde se libera o acesso às notificações.
  Future<void> openSettings();
}
