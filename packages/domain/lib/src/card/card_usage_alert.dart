/// O aviso do cartão pelo quanto do limite foi usado no mês (regra 6 da
/// planilha).
enum CardUsageAlert {
  /// Abaixo da metade do limite.
  none,

  /// A partir da metade.
  half,

  /// A partir de 80%.
  high,
}
