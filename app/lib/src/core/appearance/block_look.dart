import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// A cor e o ícone de cada grupo do que sai — fixas, assinaturas, dia a
/// dia, dívidas —, os mesmos em toda tela (17/10/2026): na linha do
/// lançamento, no Meu mês e no anel de para onde foi o dinheiro, o grupo se
/// reconhece de relance.
abstract final class BlockLook {
  /// A cor do grupo [block], do design system.
  static Color colorOf(Block block, CajuiColors colors) => switch (block) {
    Block.fixed => colors.data.fixed,
    Block.subscription => colors.data.subscription,
    Block.variable => colors.data.variable,
    Block.debt => colors.data.debt,
  };

  /// O ícone do grupo [block].
  static CajuiIconData iconOf(Block block) => switch (block) {
    Block.fixed => CajuiIconData.calendar,
    Block.subscription => CajuiIconData.repeat,
    Block.variable => CajuiIconData.wallet,
    Block.debt => CajuiIconData.debt,
  };
}
