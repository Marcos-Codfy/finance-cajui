/// Como um lançamento nasceu.
enum EntryOrigin {
  /// Digitado à mão.
  manual,

  /// Criado a partir de um comprovante compartilhado.
  share,

  /// Lançado sozinho a partir da notificação do app do banco (RN-786). É a
  /// única origem que não passou pela tela de confirmação, e por isso a
  /// revisão de domingo a traz de volta para um olhar (RN-870).
  notification,
}
