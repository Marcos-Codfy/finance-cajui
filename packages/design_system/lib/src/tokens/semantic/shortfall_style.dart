/// Como a falta do mês é pintada.
///
/// O padrão de mercado é o vermelho. A hipótese da marca, coerente com a
/// literatura mas ainda sem teste direto (D-UX-02), é que o alarme cromático
/// é justamente o que faz quem está no aperto parar de abrir o app. As duas
/// versões existem para o dono do produto escolher olhando as duas.
enum ShortfallStyle {
  /// Barro: atenção sem alarme, com o peso da tela no próximo passo.
  calm,

  /// Vermelho: o padrão de mercado.
  alarm,
}
