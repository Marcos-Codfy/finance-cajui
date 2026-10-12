/// Onde está o widget do Cajui na tela inicial do celular.
///
/// O dono pediu o botão porque "não vou saber como colocar": pôr widget no
/// Android é tocar e segurar num espaço vazio, abrir a lista de widgets e
/// arrastar — três passos que ninguém descobre sozinho. Desde o Android 8,
/// o app pode pedir ao launcher, e o sistema mostra a confirmação.
enum WidgetPlacement {
  /// Não há tela inicial: na web e nos testes.
  unavailable,

  /// O launcher não aceita o pedido do app: só pelo menu de widgets.
  manual,

  /// Ainda não está na tela, e o app pode pedir para pôr.
  absent,

  /// Já está na tela inicial.
  placed;

  /// O valor que o canal nativo manda; o que não se reconhece vira
  /// [unavailable], e a linha some em vez de oferecer o que não há.
  static WidgetPlacement of(Object? name) => values.firstWhere(
    (placement) => placement.name == name,
    orElse: () => unavailable,
  );
}
