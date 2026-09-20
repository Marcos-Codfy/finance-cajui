/// As três famílias de som, que o usuário liga e desliga separadamente.
enum SoundCategory {
  /// Toques em controles: o som mais frequente, e o primeiro a cansar.
  touches('Toques'),

  /// Confirmações: salvo, conquista, aviso.
  confirmations('Confirmações'),

  /// Sons de transição e de ambiente: folha abrindo, deslize.
  ambient('Ambiente');

  new(this.label);

  /// O nome da família, como aparece nas configurações.
  final String label;
}
