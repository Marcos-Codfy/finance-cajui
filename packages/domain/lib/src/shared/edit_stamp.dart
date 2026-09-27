/// Quem venceu entre duas edições da mesma coisa, pelo instante em que
/// foram feitas (BL-062).
///
/// Entre dois celulares do mesmo dono, "quem sincronizou por último" é uma
/// regra ruim: quem ficou sem rede um dia inteiro apagaria, ao voltar, o
/// que o outro editou de manhã. O carimbo de edição resolve: vale a edição
/// mais nova, chegue ela quando chegar.
abstract final class EditStamp {
  /// Se a edição feita em [mine] é mais nova que a feita em [theirs].
  ///
  /// Sem carimbo aqui, nunca; sem carimbo lá, sempre; sem carimbo dos dois
  /// lados — registros de antes de dois aparelhos poderem discordar —,
  /// ninguém é mais novo, e vale o que já está.
  static bool isNewer(DateTime? mine, DateTime? theirs) {
    if (mine == null) return false;
    if (theirs == null) return true;
    return mine.isAfter(theirs);
  }
}
