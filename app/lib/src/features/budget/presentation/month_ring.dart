import 'package:cajui/src/core/appearance/block_look.dart';
import 'package:cajui/src/core/navigation/coordinator_access.dart';
import 'package:cajui/src/features/ledger/presentation/ledger_coordinator.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// "Para onde foi", no Meu mês (17/10/2026): o anel com uma fatia por grupo
/// do que sai, nas cores de cada grupo. Tocar uma fatia mostra as
/// categorias dela; tocar a categoria abre os lançamentos dela no mês.
class MonthRing extends StatefulWidget {
  /// Cria o anel de [budget], com os nomes de [categories].
  const new({required this.budget, required this.categories, super.key});

  /// O mês, com as contas já feitas pelo domínio.
  final MonthBudget budget;

  /// As categorias, para dar nome a cada linha.
  final Map<String, Category> categories;

  @override
  State<MonthRing> createState() => _MonthRingState();
}

class _MonthRingState extends State<MonthRing> {
  static const List<(Block, String)> _blocks = [
    (Block.fixed, 'Contas fixas'),
    (Block.subscription, 'Assinaturas'),
    (Block.variable, 'Dia a dia'),
    (Block.debt, 'Dívidas'),
  ];

  int? _selected;

  @override
  Widget build(BuildContext context) {
    final budget = widget.budget;
    final colors = CajuiTheme.of(context).colors;
    final chosen = _selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CajuiSectionTitle('Para onde foi'),
        CajuiRingChart(
          slices: [
            for (final (block, label) in _blocks)
              CajuiRingSlice(
                label: label,
                cents: budget.totalOf(block).cents,
                color: BlockLook.colorOf(block, colors),
              ),
          ],
          total: budget.totalOut.cents,
          centerLabel: 'Sai no mês',
          selected: chosen,
          onSelected: (index) =>
              setState(() => _selected = index == chosen ? null : index),
        ),
        if (chosen != null) ..._items(context, _blocks[chosen].$1),
      ],
    );
  }

  /// As categorias do grupo escolhido, cada uma levando aos lançamentos.
  List<Widget> _items(BuildContext context, Block block) => [
    const SizedBox(height: CajuiSpacing.md),
    for (final item in widget.budget.itemsOf(block))
      if (item.counted.isPositive)
        CajuiListRow(
          title: widget.categories[item.categoryId]?.name ?? 'Outra',
          trailing: CajuiAmountText(item.counted.cents),
          semanticLabel:
              '${widget.categories[item.categoryId]?.name ?? 'Outra'}, '
              'ver os lançamentos',
          onPressed: () => context
              .coordinator(ledgerCoordinatorProvider)
              .openEntries(
                categoryId: item.categoryId,
                month: widget.budget.month,
              ),
        ),
  ];
}
