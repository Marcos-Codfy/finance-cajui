import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// As escolhas de uma linha de conta em fichas: o grupo, o tipo de gasto do
/// grupo e onde se paga.
///
/// O tipo de gasto só oferece categorias do grupo escolhido — assinatura
/// não vira mercado sem querer —, e já vem marcado quando o grupo tem uma
/// só.
final class BillLineChoices {
  /// Cria as escolhas sobre [categories] e [methods].
  const new({required this.categories, required this.methods});

  /// As categorias do livro.
  final List<Category> categories;

  /// As formas de pagamento, com os cartões.
  final List<PaymentMethod> methods;

  static const Map<LineGroup, String> _groupNames = {
    LineGroup.fixedBill: 'Conta fixa',
    LineGroup.subscription: 'Assinatura',
    LineGroup.dayToDay: 'Dia a dia',
  };

  /// As categorias de [group].
  List<Category> of(LineGroup group) =>
      categories.where((category) => category.block == group.block).toList();

  /// A categoria em vigor: [chosen] se é do grupo, ou a única do grupo.
  String? categoryFor(LineGroup group, String? chosen) {
    final options = of(group);
    if (options.any((category) => category.id == chosen)) return chosen;
    return options.length == 1 ? options.single.id : null;
  }

  /// As fichas do grupo.
  List<Widget> groups(LineGroup selected, ValueChanged<LineGroup> onPick) => [
    const CajuiSectionTitle('Grupo'),
    _wrap([
      for (final group in LineGroup.values)
        CajuiChip(
          label: _groupNames[group]!,
          selected: group == selected,
          onSelected: (_) => onPick(group),
        ),
    ]),
  ];

  /// As fichas do tipo de gasto de [group].
  List<Widget> categoriesOf(
    LineGroup group,
    String? selected,
    ValueChanged<String> onPick,
  ) => [
    const CajuiSectionTitle('Tipo de gasto'),
    _wrap([
      for (final category in of(group))
        CajuiChip(
          label: category.name,
          selected: category.id == selected,
          onSelected: (_) => onPick(category.id),
        ),
    ]),
  ];

  /// As fichas de onde se paga, com "Não sei" para deixar em branco.
  List<Widget> payments(String? selected, ValueChanged<String?> onPick) => [
    const CajuiSectionTitle('Onde eu pago'),
    _wrap([
      CajuiChip(
        label: 'Não sei',
        selected: selected == null,
        onSelected: (_) => onPick(null),
      ),
      for (final method in methods)
        CajuiChip(
          label: method.name,
          selected: method.id == selected,
          onSelected: (_) => onPick(method.id),
        ),
    ]),
  ];

  static Widget _wrap(List<Widget> chips) => Padding(
    padding: const EdgeInsets.only(bottom: CajuiSpacing.md),
    child: Wrap(
      spacing: CajuiSpacing.sm,
      runSpacing: CajuiSpacing.sm,
      children: chips,
    ),
  );
}
