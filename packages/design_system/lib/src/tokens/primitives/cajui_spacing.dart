/// Escala de espaçamento, em pixels lógicos, sobre uma base de 4.
///
/// Escala curta de propósito: com poucos degraus, o ritmo vertical se repete
/// de tela em tela sem ninguém precisar combinar.
abstract final class CajuiSpacing {
  /// 2 — ajuste fino entre ícone e texto.
  static const double xxs = 2;

  /// 4 — elementos colados, como valor e unidade.
  static const double xs = 4;

  /// 8 — itens de uma mesma linha.
  static const double sm = 8;

  /// 12 — linhas de uma lista.
  static const double md = 12;

  /// 16 — margem lateral da página e respiro padrão.
  static const double lg = 16;

  /// 20 — respiro interno de cartão.
  static const double xl = 20;

  /// 24 — entre grupos dentro de uma seção.
  static const double xxl = 24;

  /// 32 — entre seções.
  static const double section = 32;

  /// 48 — entre blocos grandes, e o lado mínimo do alvo de toque.
  static const double block = 48;

  /// 64 — respiro de abertura de tela.
  static const double hero = 64;

  /// Lado mínimo de qualquer alvo de toque no Android (RNF-A11Y-05).
  static const double touchTarget = 48;
}
