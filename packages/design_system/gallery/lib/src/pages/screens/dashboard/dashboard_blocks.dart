import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/shared/stat_card.dart';

/// Os blocos do painel, com os números do exemplo único da especificação
/// (setembro de 2026, semana 3).
abstract final class DashboardBlocks {
  /// O número-manchete: quanto dá para gastar nesta semana.
  static Widget week({int limit = 22647, int spent = 8620}) => StatCard(
    label: 'Dá para gastar esta semana',
    cents: limit - spent,
    large: true,
    meter: spent / limit,
    caption:
        '${BrlFormatter.format(spent)} de ${BrlFormatter.format(limit)} '
        'já usados',
  );

  /// A sobra prevista do mês, em dinheiro.
  static Widget leftover({int? cents = 55800}) => StatCard(
    label: 'Sobra prevista de setembro',
    cents: cents,
    tone: CajuiAmountTone.positive,
    caption: cents == null ? null : 'Contando os variáveis pelo pior caso',
  );

  /// O vale alimentação: moeda à parte, nunca somada ao dinheiro (RN-111).
  static Widget voucher() => StatCard(
    label: 'Vale alimentação',
    cents: 41260,
    tone: CajuiAmountTone.accent,
    caption: 'de ${BrlFormatter.format(65000)} · só para alimentação',
    sunken: true,
  );

  /// Quanto da renda já tem destino antes de o mês começar: fixos e dívidas
  /// (1.300 + 362 sobre 3.200).
  static Widget committed() => const StatCard(
    label: 'Renda comprometida',
    cents: 166200,
    meter: 0.52,
    caption: '52% da renda, em fixos e dívidas',
  );

  /// Os blocos de um mês andando normalmente.
  static List<Widget> regular() => [
    week(),
    leftover(),
    voucher(),
    committed(),
  ];
}
