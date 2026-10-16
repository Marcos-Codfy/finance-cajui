import 'dart:ui' show Color;

/// Os tons do cerrado para o plástico do cartão de crédito: cada par é o
/// alto e o baixo do gradiente. Todos são escuros o bastante para o texto
/// claro do cartão passar de 4,5:1 nas duas pontas (`contrast_audit_test`):
/// o ipê-amarelo é um mostarda, não o amarelo da flor, por isso.
abstract final class CajuiCerradoPalette {
  /// Pequi: o miolo âmbar do fruto.
  static const pequiTop = Color(0xFF9A5B00);

  /// Pequi, a ponta escura.
  static const pequiBottom = Color(0xFF6E4000);

  /// Ipê-amarelo, em mostarda.
  static const ipeAmareloTop = Color(0xFF8A6D00);

  /// Ipê-amarelo, a ponta escura.
  static const ipeAmareloBottom = Color(0xFF5E4A00);

  /// Ipê-roxo: o rosa-arroxeado da florada de agosto.
  static const ipeRoxoTop = Color(0xFF8E2F7A);

  /// Ipê-roxo, a ponta escura.
  static const ipeRoxoBottom = Color(0xFF5E1F51);

  /// Buriti: o vinho da casca do fruto.
  static const buritiTop = Color(0xFF7A2E1A);

  /// Buriti, a ponta escura.
  static const buritiBottom = Color(0xFF52190D);

  /// Folha do cerrado: o verde-oliva da vegetação seca.
  static const folhaTop = Color(0xFF4E6B2E);

  /// Folha, a ponta escura.
  static const folhaBottom = Color(0xFF34491E);

  /// Barro: a terra vermelha das estradas.
  static const barroTop = Color(0xFFA3452A);

  /// Barro, a ponta escura.
  static const barroBottom = Color(0xFF73301D);

  /// Céu de seca: o azul limpo de julho.
  static const ceuTop = Color(0xFF2F5E8C);

  /// Céu, a ponta escura.
  static const ceuBottom = Color(0xFF1F4166);

  /// O texto e o chip sobre qualquer tom: o branco-papel.
  static const ink = Color(0xFFFFFBF5);
}
