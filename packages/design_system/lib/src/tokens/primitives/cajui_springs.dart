import 'package:flutter/physics.dart';

/// Molas: o movimento que segue uma força, e não um relógio.
///
/// A curva `CajuiCurves.spring` imita uma mola num tempo fixo. Estas são molas
/// de verdade, para o que reage a algo que não tem hora para acabar — o
/// celular inclinando, a água balançando. Cada uma diz quanto puxa
/// (`stiffness`) e quanto freia (`damping`); a razão entre as duas decide se
/// ela ultrapassa o destino e volta, ou se chega de mansinho.
abstract final class CajuiSprings {
  /// Água no pote: freia pouco (razão 0,24), então vai e volta umas vezes,
  /// cada vez menos, e assenta em cerca de dois segundos — como um copo
  /// pousado na mesa.
  static const slosh = SpringDescription(mass: 1, stiffness: 90, damping: 4.5);

  /// O nível da água subindo ou baixando: uma ultrapassagem pequena, de uns
  /// 4%, que dá peso ao líquido sem parecer que ele quica.
  static const level = SpringDescription(mass: 1, stiffness: 60, damping: 11);

  /// Cartão seguindo a mão ou o giroscópio: perto do amortecimento crítico
  /// (razão 0,85). Acompanha sem tremer — tremor num cartão parece defeito.
  static const tilt = SpringDescription(mass: 1, stiffness: 140, damping: 20);

  /// Barra crescendo no gráfico: ultrapassa um pouco a altura certa e volta.
  static const grow = SpringDescription(mass: 1, stiffness: 180, damping: 16);

  /// O carrossel encaixando na página: razão 0,83, uma ultrapassagem de
  /// uns 1%, que se sente como trava e não se vê como quique. Assenta em
  /// uns 350 ms, abaixo do tempo de uma troca de tela.
  static const page = SpringDescription(mass: 1, stiffness: 210, damping: 24);
}
