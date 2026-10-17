import 'package:design_system/src/tokens/semantic/cajui_colors.dart';
import 'package:flutter/widgets.dart';

/// As cores das ilustrações do Cerrado, tiradas dos tokens do tema.
///
/// Nenhuma cor nasce aqui: cada papel do desenho aponta para um token que
/// já existe e já tem par no escuro. Trocar a vereda no tema troca a folha.
@immutable
final class CerradoPalette {
  /// Cria a paleta com cada papel já resolvido.
  const new({
    required this.backdrop,
    required this.wood,
    required this.leaf,
    required this.vein,
    required this.petal,
    required this.heart,
    required this.fruit,
    required this.sheen,
  });

  /// A paleta do tema de [colors].
  factory of(CajuiColors colors) => CerradoPalette(
    backdrop: colors.surface.sunken,
    wood: colors.text.muted,
    leaf: colors.intent.positive,
    vein: colors.intent.positiveSubtle,
    petal: colors.brand.gold,
    heart: colors.brand.fruitGradient[1],
    fruit: colors.brand.fruitGradient,
    sheen: colors.brand.sheen,
  );

  /// O disco por trás do desenho: o fundo afundado, que some no tema.
  final Color backdrop;

  /// Galho, pecíolo e castanha: o tom calmo do texto secundário.
  final Color wood;

  /// A folha: a vereda.
  final Color leaf;

  /// As nervuras: o fundo sutil da vereda, que contrasta com ela.
  final Color vein;

  /// As pétalas do ipê: o capim dourado.
  final Color petal;

  /// O miolo da flor: o meio do gradiente do fruto.
  final Color heart;

  /// As três paradas do gradiente do fruto, do topo à base.
  final List<Color> fruit;

  /// O reflexo no alto do fruto.
  final Color sheen;

  @override
  bool operator ==(Object other) =>
      other is CerradoPalette &&
      other.backdrop == backdrop &&
      other.wood == wood &&
      other.leaf == leaf &&
      other.vein == vein &&
      other.petal == petal &&
      other.heart == heart &&
      identical(other.fruit, fruit) &&
      other.sheen == sheen;

  @override
  int get hashCode =>
      Object.hash(backdrop, wood, leaf, vein, petal, heart, fruit, sheen);
}
