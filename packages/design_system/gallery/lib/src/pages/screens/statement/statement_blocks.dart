import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/screens/shared/stat_card.dart';

/// Os blocos da tela de fatura, com os números do exemplo da especificação:
/// fatura de R$ 1.240,00, vencendo em 05/10, com R$ 640,00 já reservados.
abstract final class StatementBlocks {
  /// O total calculado da fatura. Nunca é digitado nem vira despesa (RN-330).
  static Widget total({int cents = 124000, String? caption}) => StatCard(
    label: 'Total da fatura',
    cents: cents,
    large: true,
    caption: caption ?? 'Vence em 05/10 · fecha em 3 dias',
  );

  /// A composição por bloco (RN-331).
  static Widget composition() => CajuiCard(
    child: Column(
      children: [
        _part('Variáveis', 'Mercado, lazer, transporte', 89000),
        _part('Fixos', 'Internet e celular', 20000),
        _part('Parcelas', 'Geladeira · 4 de 10', 15000),
      ],
    ),
  );

  static Widget _part(String block, String detail, int cents) => CajuiListRow(
    title: block,
    subtitle: detail,
    trailing: CajuiAmountText(cents),
  );

  /// A reserva: quanto do dinheiro do mês já tem destino (RN-320 e RN-321).
  static Widget reserve({int cents = 64000}) => Padding(
    padding: const EdgeInsets.only(top: CajuiSpacing.lg),
    child: StatCard(
      label: 'Reservado para a fatura',
      cents: cents,
      tone: CajuiAmountTone.muted,
      sunken: true,
      caption:
          'Compras à vista já contadas em setembro. Não reduz a sobra de '
          'novo.',
    ),
  );

  /// Uma fatura em aberto, do jeito que aparece na maior parte do mês.
  static List<Widget> open() => [total(), composition(), reserve()];
}
