/// Como está um item da linha do tempo.
enum CajuiTimelineMark {
  /// Feito: a conta paga. Ponto cheio.
  done,

  /// Por fazer, ainda no prazo. Ponto vazio.
  pending,

  /// Por fazer, e o dia já passou. Ponto no tom de falta — sem alarme.
  late,
}
