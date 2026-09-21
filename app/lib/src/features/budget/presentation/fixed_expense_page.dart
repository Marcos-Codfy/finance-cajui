import 'package:cajui/src/features/ledger/application/ledger_book.dart';
import 'package:cajui/src/features/ledger/presentation/option_picker_page.dart';
import 'package:design_system/design_system.dart';
import 'package:domain/domain.dart';
import 'package:flutter/widgets.dart';

/// Uma conta fixa: o que é, quanto custa e em que dia vence.
///
/// Fecha devolvendo a conta. O dia de vencimento sai de uma lista de 1 a 31:
/// dia que não existe não é recusado — não chega a ser oferecido.
class FixedExpensePage extends StatefulWidget {
  /// Cria a tela. Com [existing], edita; sem, cria com o identificador [id].
  const new({required this.book, required this.id, this.existing, super.key});

  /// O livro, de onde saem categorias e formas de pagamento.
  final LedgerBook book;

  /// O identificador da conta.
  final String id;

  /// A conta em edição.
  final FixedExpense? existing;

  /// Abre a tela e espera a conta.
  static Future<FixedExpense?> open(
    BuildContext context, {
    required LedgerBook book,
    required String id,
    FixedExpense? existing,
  }) {
    return Navigator.of(context).push<FixedExpense>(
      CajuiPageRoute(
        builder: (_) =>
            FixedExpensePage(book: book, id: id, existing: existing),
      ),
    );
  }

  @override
  State<FixedExpensePage> createState() => _FixedExpensePageState();
}

class _FixedExpensePageState extends State<FixedExpensePage> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late int _cents = widget.existing?.amount.cents ?? 0;
  late int? _dueDay = widget.existing?.dueDay;
  late Category? _category = _fixedCategories
      .where((category) => category.id == widget.existing?.categoryId)
      .firstOrNull;

  List<Category> get _fixedCategories => [
    ...widget.book.categories.where((c) => c.block == Block.fixed),
  ];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDay() async {
    final picked = await OptionPickerPage.open<int>(
      context,
      title: 'Dia do vencimento',
      options: [for (var day = 1; day <= 31; day++) day],
      labelOf: (day) => 'dia $day',
      selected: _dueDay,
    );
    if (picked != null) setState(() => _dueDay = picked);
  }

  Future<void> _pickCategory() async {
    final picked = await OptionPickerPage.open<Category>(
      context,
      title: 'Categoria',
      options: _fixedCategories,
      labelOf: (category) => category.name,
      selected: _category,
    );
    if (picked != null) setState(() => _category = picked);
  }

  FixedExpense? get _expense {
    final (day, category) = (_dueDay, _category);
    final name = _name.text.trim();
    if (day == null || category == null || name.isEmpty || _cents <= 0) {
      return null;
    }
    return FixedExpense(
      id: widget.id,
      name: name,
      amount: Money.fromCents(_cents),
      dueDay: day,
      categoryId: category.id,
      // Por onde a conta é paga entra com o pagamento de cada mês; o plano
      // só precisa de um padrão, e Pix é o mais comum.
      paymentMethodId: widget.existing?.paymentMethodId ?? 'pix',
    );
  }

  @override
  Widget build(BuildContext context) {
    final expense = _expense;
    return CajuiScreen(
      title: 'Conta fixa',
      onBack: Navigator.of(context).pop,
      footer: CajuiButton(
        label: 'Guardar',
        expand: true,
        onPressed: expense == null
            ? null
            : () => Navigator.of(context).pop(expense),
      ),
      children: [..._whatAndHowMuch(), _gap, ..._whenAndWhere()],
    );
  }

  static const _gap = SizedBox(height: CajuiSpacing.lg);

  List<Widget> _whatAndHowMuch() => [
    CajuiTextField(
      label: 'O que é',
      hint: 'Aluguel, internet, celular',
      controller: _name,
      onChanged: (_) => setState(() {}),
    ),
    _gap,
    CajuiAmountField(
      label: 'Valor por mês',
      initialCents: _cents,
      onChanged: (cents) => setState(() => _cents = cents),
    ),
  ];

  List<Widget> _whenAndWhere() => [
    CajuiSelectField(
      label: 'Vence em',
      value: _dueDay == null ? null : 'dia $_dueDay',
      helper: 'Em mês mais curto, vale o último dia',
      onPressed: _pickDay,
    ),
    _gap,
    CajuiSelectField(
      label: 'Categoria',
      value: _category?.name,
      onPressed: _pickCategory,
    ),
  ];
}
