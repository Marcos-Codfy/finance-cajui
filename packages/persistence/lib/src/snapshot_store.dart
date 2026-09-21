/// Onde moram os resumos: o estado já calculado até um certo evento, para o
/// servidor não ter de reaplicar a história inteira ao subir (ADR-004).
///
/// Um resumo é sempre **descartável**: a fonte da verdade é o registro de
/// eventos. Se um resumo sumir, estiver ilegível ou discordar do registro
/// (`E-DATA-02`), ele é refeito a partir dos eventos.
abstract interface class SnapshotStore {
  /// Grava o resumo [name], substituindo o anterior de uma vez só: quem lê
  /// nunca encontra um arquivo pela metade.
  Future<void> write(String name, Map<String, Object?> state);

  /// Lê o resumo [name]. Devolve nulo se ele não existe **ou não abre** — nos
  /// dois casos a saída é a mesma: refazer a partir dos eventos.
  Future<Map<String, Object?>?> read(String name);
}
